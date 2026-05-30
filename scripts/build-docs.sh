#!/bin/bash
#
# build-docs.sh — Build, preview, export, and deploy DocC documentation for FlyHUD
#
# This script automates the full documentation pipeline:
#   1. Builds DocC documentation for the "Example iOS" scheme (which depends
#      on all framework targets) via `xcodebuild docbuild`
#   2. Locates the generated .doccarchive files in DerivedData
#   3. Merges them into a single combined archive using `xcrun docc merge`
#   4. Optionally exports the archive as a static site and/or deploys to
#      the gh-pages branch on GitHub
#
# The merged archive uses a synthesized landing page named "FlyHUD" that
# links to all four framework documentations (FlyHUD, FlyIndicatorHUD,
# FlyProgressHUD, FlyHUDSwiftUI).
#
# Usage:
#   ./scripts/build-docs.sh [version] [destination]
#   ./scripts/build-docs.sh clean
#   ./scripts/build-docs.sh preview [port]
#   ./scripts/build-docs.sh export [version] [output-dir]
#   ./scripts/build-docs.sh deploy [version]
#
# Commands:
#   clean         Remove all documentation build artifacts (.build/docs/,
#                 .build/docbuild/) and run `xcodebuild clean` to clear
#                 the workspace build cache.
#   preview       Start a local HTTP server to preview the built documentation
#                 in a browser. Optionally specify a port (default: 8000).
#   export        Build documentation and transform it into a static site
#                 for GitHub Pages deployment. If version is specified, always
#                 rebuilds first. If omitted, exports the existing archive
#                 (auto-detects version from it).
#                 (default output-dir: .build/site)
#   deploy        Build, export, and push documentation to the gh-pages branch
#                 on GitHub. If version is specified, rebuilds first. If omitted,
#                 deploys the existing archive (auto-detects version from it).
#                 For versioned releases (e.g., 1.6.0): adds the new version
#                 directory. For "main": replaces the existing main/ directory.
#                 Never deletes other version directories.
#
# Arguments (for build):
#   version       Documentation version string used in the hosting base path.
#                 This appears in URLs: /FlyHUD/<version>/documentation/...
#                 (default: "main")
#   destination   Xcode build destination string. If omitted, the script
#                 auto-detects the first available iPhone simulator.
#                 (default: auto-detect)
#
# Examples:
#   ./scripts/build-docs.sh                          # Build docs for "main" branch
#   ./scripts/build-docs.sh 1.6.0                    # Build docs for release tag
#   ./scripts/build-docs.sh clean                    # Remove all build artifacts
#   ./scripts/build-docs.sh preview                  # Preview docs at localhost:8000
#   ./scripts/build-docs.sh preview 9000             # Preview on custom port
#   ./scripts/build-docs.sh export                   # Export existing archive (auto-detect version)
#   ./scripts/build-docs.sh export 1.6.0             # Build + export to .build/site/1.6.0/
#   ./scripts/build-docs.sh export main ./my-site    # Build + export to ./my-site/main/
#   ./scripts/build-docs.sh deploy                   # Deploy existing archive (auto-detect version)
#   ./scripts/build-docs.sh deploy 1.6.0             # Build + export + push to gh-pages branch
#   ./scripts/build-docs.sh deploy main              # Update main/ on gh-pages branch
#   ./scripts/build-docs.sh main "platform=iOS Simulator,name=iPhone 17 Pro,arch=arm64"
#
# Output:
#   .build/docs/FlyHUD.doccarchive  — Merged documentation archive
#
# Prerequisites:
#   - Xcode 15.0+ with DocC support
#   - At least one available iPhone simulator
#   - FlyHUD.xcworkspace with "Example iOS" scheme
#
# Environment:
#   The script uses .build/docbuild/ as DerivedData to avoid polluting
#   the default ~/Library/Developer/Xcode/DerivedData/ directory.
#   Both .build/docs/ and .build/docbuild/ are git-ignored.
#

set -euo pipefail

# Verify we're in the repository root
if [[ ! -d "FlyHUD.xcworkspace" ]]; then
    printf "\033[31m✗ Error:\033[0m Must be run from the FlyHUD repository root (where FlyHUD.xcworkspace resides).\n" >&2
    exit 1
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Terminal Colors & Formatting                                        │
# └─────────────────────────────────────────────────────────────────────┘

# ANSI color codes for styled terminal output.
# Defined using $'...' (ANSI-C quoting) which is compatible with bash 3.2+.
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
CYAN=$'\033[36m'
RED=$'\033[31m'

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Helper Functions                                                    │
# └─────────────────────────────────────────────────────────────────────┘

# Print a section header with a styled box
print_header() {
    printf "\n"
    printf "  ${BLUE}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}\n"
    printf "  ${BLUE}${BOLD}║${RESET}  ${BOLD}%s${RESET}\n" "$1"
    printf "  ${BLUE}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"
}

# Print a numbered step (e.g., [1/4] Doing something)
print_step() {
    printf "\n  ${CYAN}${BOLD}[%s/%s]${RESET} %s\n" "$1" "$TOTAL_STEPS" "$2"
}

# Print a success line with green checkmark
print_success() {
    printf "       ${GREEN}✓${RESET} %s\n" "$1"
}

# Print a warning line with yellow marker
print_warn() {
    printf "       ${YELLOW}⚠${RESET} %s\n" "$1"
}

# Print an error message and exit with code 1
print_error() {
    printf "\n  ${RED}${BOLD}✗ Error:${RESET} %s\n\n" "$1" >&2
    exit 1
}

# Print a key-value info line
print_info() {
    printf "       ${DIM}%-12s${RESET} %s\n" "$1" "$2"
}

# Print a list of issues (errors/warnings) with color coding
print_issues() {
    local issues="$1"
    printf "\n"
    shopt -s nocasematch
    while IFS= read -r line; do
        if [[ "$line" == *"error:"* ]]; then
            printf "       ${RED}✗${RESET} %s\n" "$line"
        else
            printf "       ${YELLOW}⚠${RESET} %s\n" "$line"
        fi
    done <<< "$issues"
    shopt -u nocasematch
    printf "\n"
}

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Clean Command                                                       │
# └─────────────────────────────────────────────────────────────────────┘

# Handle "clean" subcommand — removes all documentation build artifacts.
# This includes DerivedData, output archives, export site, deploy temp, and preview.
if [[ "${1:-}" == "clean" ]]; then
    TOTAL_STEPS=1
    print_header "FlyHUD Documentation Clean"
    print_step 1 "Removing documentation build artifacts"

    REMOVED=0
    if [[ -d ".build/docbuild" ]]; then
        rm -rf ".build/docbuild"
        print_success "Removed .build/docbuild/"
        REMOVED=$((REMOVED + 1))
    fi
    if [[ -d ".build/docs" ]]; then
        rm -rf ".build/docs"
        print_success "Removed .build/docs/"
        REMOVED=$((REMOVED + 1))
    fi
    # Deploy/export artifacts (not under .build/docs/)
    for dir in .build/site .build/deploy-temp; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            print_success "Removed ${dir}/"
            REMOVED=$((REMOVED + 1))
        fi
    done

    # Run xcodebuild clean to clear workspace build cache
    if [[ -f "FlyHUD.xcworkspace/contents.xcworkspacedata" ]]; then
        xcodebuild clean \
            -workspace "FlyHUD.xcworkspace" \
            -scheme "Example iOS" \
            -quiet 2>/dev/null && \
        print_success "Xcode workspace build cache cleared" || \
        print_warn "xcodebuild clean skipped (non-critical)"
        REMOVED=$((REMOVED + 1))
    fi

    if [[ $REMOVED -eq 0 ]]; then
        print_info "" "Nothing to clean (directories don't exist)"
    fi

    printf "\n  ${GREEN}${BOLD}✓${RESET} Clean complete.\n\n"
    exit 0
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Preview Command                                                     │
# └─────────────────────────────────────────────────────────────────────┘

# Handle "preview" subcommand — starts a local HTTP server for the docs.
# The .doccarchive is a SPA with a base path prefix, so we create a symlink
# structure that matches the expected URL path, then serve it.
if [[ "${1:-}" == "preview" ]]; then
    TOTAL_STEPS=1
    ARCHIVE_PATH=".build/docs/FlyHUD.doccarchive"
    PORT="${2:-8000}"

    if [[ ! -d "$ARCHIVE_PATH" ]]; then
        print_error "Documentation not built yet. Run './scripts/build-docs.sh' first."
    fi

    # Read the baseUrl from index.html to determine the hosting path
    BASE_PATH=$(grep -o 'var baseUrl = "[^"]*"' "$ARCHIVE_PATH/index.html" | sed 's/var baseUrl = "//;s/"$//' | sed 's:/*$::')

    if [[ -z "$BASE_PATH" || "$BASE_PATH" == "/" ]]; then
        # No base path — serve directly
        SERVE_DIR="$ARCHIVE_PATH"
    else
        # Create temp directory with path structure matching baseUrl
        SERVE_DIR=".build/docs/_preview"
        rm -rf "$SERVE_DIR"
        mkdir -p "$SERVE_DIR/$(dirname "$BASE_PATH")"
        ln -sf "$(cd "$ARCHIVE_PATH" && pwd)" "$SERVE_DIR${BASE_PATH}"
    fi

    print_header "FlyHUD Documentation Preview"
    print_step 1 "Starting local server on port ${PORT}"
    print_info "URL:" "http://localhost:${PORT}${BASE_PATH}/documentation/"
    print_info "Archive:" "$ARCHIVE_PATH"
    printf "\n       ${DIM}Press Ctrl+C to stop${RESET}\n\n"

    python3 -m http.server "$PORT" -d "$SERVE_DIR"
    exit 0
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Export Command                                                      │
# └─────────────────────────────────────────────────────────────────────┘

# Handle "export" subcommand — builds documentation and transforms it into
# a static site suitable for GitHub Pages deployment.
#
# Output structure (matching gh-pages branch layout):
#   <output-dir>/<version>/documentation/...
#
# Usage: ./scripts/build-docs.sh export [version] [output-dir]
if [[ "${1:-}" == "export" ]]; then
    ARCHIVE_PATH=".build/docs/FlyHUD.doccarchive"

    if [[ -n "${2:-}" ]]; then
        # Version specified — always rebuild to ensure consistency
        EXPORT_VERSION="$2"
        EXPORT_OUTPUT="${3:-.build/site}"
        "$0" "${EXPORT_VERSION}"
        printf "\n"
    else
        # No version — use existing archive, auto-detect version from baseUrl
        if [[ ! -d "$ARCHIVE_PATH" ]]; then
            print_error "No archive found. Specify a version: ./scripts/build-docs.sh export 1.6.0"
        fi
        EXPORT_VERSION=$(grep -o 'var baseUrl = "[^"]*"' "$ARCHIVE_PATH/index.html" \
            | sed 's|var baseUrl = "/FlyHUD/||;s|/"||' )
        if [[ -z "$EXPORT_VERSION" ]]; then
            EXPORT_VERSION="main"
        fi
        EXPORT_OUTPUT="${3:-.build/site}"
    fi

    HOSTING_BASE_PATH="/FlyHUD/${EXPORT_VERSION}"
    EXPORT_DEST="${EXPORT_OUTPUT}/${EXPORT_VERSION}"

    TOTAL_STEPS=1
    print_header "FlyHUD Documentation Export"
    print_info "Version:" "${EXPORT_VERSION}"
    print_info "Output:" "${EXPORT_DEST}/"
    print_info "Base Path:" "${HOSTING_BASE_PATH}"

    # Transform for static hosting
    print_step 1 "Transforming for static hosting"

    # Remove previous export for this version
    rm -rf "${EXPORT_DEST}"
    mkdir -p "${EXPORT_DEST}"

    xcrun docc process-archive transform-for-static-hosting \
        "${ARCHIVE_PATH}" \
        --hosting-base-path "${HOSTING_BASE_PATH}" \
        --output-path "${EXPORT_DEST}"

    print_success "Exported to ${EXPORT_DEST}/"

    # Show summary
    FILE_COUNT=$(find "${EXPORT_DEST}" -type f | wc -l | tr -d ' ')
    DIR_SIZE=$(du -sh "${EXPORT_DEST}" | cut -f1)

    printf "\n"
    printf "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}\n"
    printf "  ${GREEN}${BOLD}║${RESET}  ${GREEN}${BOLD}✓ Export complete!${RESET}\n"
    printf "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"
    printf "\n"
    print_info "Output:" "${EXPORT_DEST}/"
    print_info "Files:" "${FILE_COUNT}"
    print_info "Size:" "${DIR_SIZE}"
    printf "\n"
    printf "  ${BOLD}Deploy to GitHub Pages:${RESET}\n"
    printf "  ${DIM}  ./scripts/build-docs.sh deploy ${EXPORT_VERSION}${RESET}\n"
    printf "\n"
    exit 0
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Deploy Command                                                      │
# └─────────────────────────────────────────────────────────────────────┘

# Handle "deploy" subcommand — builds, exports, and deploys documentation
# to the gh-pages branch of the remote repository.
#
# For versioned releases (e.g., 1.6.0): adds new version without modifying
# existing versions. For "main": replaces the existing main/ directory.
#
# Usage: ./scripts/build-docs.sh deploy [version]
if [[ "${1:-}" == "deploy" ]]; then
    DEPLOY_REMOTE=$(git remote get-url origin 2>/dev/null || echo "git@github.com:liam-i/FlyHUD.git")
    DEPLOY_BRANCH="gh-pages"
    DEPLOY_TEMP=".build/deploy-temp"
    ARCHIVE_PATH=".build/docs/FlyHUD.doccarchive"

    # Cleanup temp directory on exit (success, error, or interrupt)
    trap 'rm -rf "${DEPLOY_TEMP}"' EXIT INT TERM

    if [[ -n "${2:-}" ]]; then
        # Version specified — rebuild + export
        DEPLOY_VERSION="$2"
        "$0" export "${DEPLOY_VERSION}" ".build/site"
    else
        # No version — auto-detect from existing archive, export only
        if [[ ! -d "$ARCHIVE_PATH" ]]; then
            print_error "No archive found. Specify a version: ./scripts/build-docs.sh deploy 1.6.0"
        fi
        DEPLOY_VERSION=$(grep -o 'var baseUrl = "[^"]*"' "$ARCHIVE_PATH/index.html" \
            | sed 's|var baseUrl = "/FlyHUD/||;s|/"||')
        if [[ -z "$DEPLOY_VERSION" ]]; then
            DEPLOY_VERSION="main"
        fi
        "$0" export
    fi

    EXPORT_DEST=".build/site/${DEPLOY_VERSION}"
    printf "\n"

    TOTAL_STEPS=3
    print_header "FlyHUD Documentation Deploy"
    print_info "Version:" "${DEPLOY_VERSION}"
    print_info "Remote:" "${DEPLOY_REMOTE}"
    print_info "Branch:" "${DEPLOY_BRANCH}"

    # Step 1: Clone gh-pages branch (shallow)
    print_step 1 "Cloning ${DEPLOY_BRANCH} branch"

    rm -rf "${DEPLOY_TEMP}"
    if git ls-remote --exit-code --heads "${DEPLOY_REMOTE}" "${DEPLOY_BRANCH}" > /dev/null 2>&1; then
        git clone --branch "${DEPLOY_BRANCH}" --single-branch --depth 1 \
            "${DEPLOY_REMOTE}" "${DEPLOY_TEMP}" 2>/dev/null
        print_success "Cloned existing ${DEPLOY_BRANCH} branch"
    else
        # gh-pages branch doesn't exist yet — create an orphan
        mkdir -p "${DEPLOY_TEMP}"
        git -C "${DEPLOY_TEMP}" init -b "${DEPLOY_BRANCH}" 2>/dev/null
        git -C "${DEPLOY_TEMP}" remote add origin "${DEPLOY_REMOTE}" 2>/dev/null
        print_success "Initialized new ${DEPLOY_BRANCH} branch"
    fi

    # Step 2: Update version directory
    print_step 2 "Updating ${DEPLOY_VERSION}/ directory"

    # Safety guard: DEPLOY_VERSION must be a valid directory name (not empty, not path traversal)
    if [[ -z "$DEPLOY_VERSION" || "$DEPLOY_VERSION" == "/" || "$DEPLOY_VERSION" == "." || "$DEPLOY_VERSION" == ".." || "$DEPLOY_VERSION" == */* ]]; then
        print_error "Invalid DEPLOY_VERSION: '${DEPLOY_VERSION}'. Must be a simple name (e.g., 'main' or '1.6.0')."
    fi

    # Explicitly tell git to track deletions (more reliable than rm + git add -A
    # in shallow clones where git may fail to detect filesystem deletions).
    if [[ -d "${DEPLOY_TEMP}/${DEPLOY_VERSION}" ]]; then
        git -C "${DEPLOY_TEMP}" rm -rf "${DEPLOY_VERSION}" --quiet 2>/dev/null || true
        rm -rf "${DEPLOY_TEMP:?}/${DEPLOY_VERSION:?}"
        print_info "" "Removed old ${DEPLOY_VERSION}/ directory"
    fi

    cp -R "${EXPORT_DEST}" "${DEPLOY_TEMP}/${DEPLOY_VERSION}"
    print_success "Copied ${DEPLOY_VERSION}/ to deploy directory"

    # Step 3: Commit and push
    print_step 3 "Committing and pushing to ${DEPLOY_BRANCH}"

    # Ensure git config is available for the temp repo (CI may lack global config)
    if ! git -C "${DEPLOY_TEMP}" config user.name > /dev/null 2>&1; then
        git -C "${DEPLOY_TEMP}" config user.name "liam-i"
        git -C "${DEPLOY_TEMP}" config user.email "liam_i@163.com"
    fi

    COMMIT_ID=$(git rev-parse --short HEAD)
    # Use owner/repo@sha format for GitHub auto-linking in commit messages
    REPO_SLUG=$(echo "$DEPLOY_REMOTE" | sed -E 's|.*[:/]([^/]+/[^/.]+)(\.git)?$|\1|')
    COMMIT_MSG="Deploying to ${DEPLOY_BRANCH} from @ ${REPO_SLUG}@${COMMIT_ID} 🚀"

    git -C "${DEPLOY_TEMP}" add -A

    # Commit (may produce "nothing to commit" which is fine)
    if ! git -C "${DEPLOY_TEMP}" diff --cached --quiet 2>/dev/null; then
        git -C "${DEPLOY_TEMP}" commit -m "${COMMIT_MSG}" || \
            print_error "git commit failed. Check git configuration."
    else
        print_warn "No changes to commit (documentation unchanged)"
    fi

    # Push — use force-with-lease for safety: only overwrites remote if no one else
    # has pushed since our clone. Falls back to --force if remote diverged
    # (acceptable for automated docs deployment where we always want our state to win).
    if ! git -C "${DEPLOY_TEMP}" push --force-with-lease origin "${DEPLOY_BRANCH}" 2>&1; then
        print_warn "force-with-lease rejected (remote may have diverged), retrying with --force"
        if ! git -C "${DEPLOY_TEMP}" push --force origin "${DEPLOY_BRANCH}" 2>&1; then
            print_error "git push failed. Check remote access and authentication."
        fi
    fi
    print_success "Pushed to ${DEPLOY_BRANCH}"

    printf "\n"
    printf "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}\n"
    printf "  ${GREEN}${BOLD}║${RESET}  ${GREEN}${BOLD}✓ Deploy complete!${RESET}\n"
    printf "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"
    printf "\n"
    print_info "Version:" "${DEPLOY_VERSION}"
    print_info "Commit:" "${COMMIT_MSG}"
    printf "\n"
    printf "  ${BOLD}Documentation URL:${RESET}\n"
    printf "  ${DIM}  https://liam-i.github.io/FlyHUD/${DEPLOY_VERSION}/documentation/flyhud${RESET}\n"
    printf "\n"
    printf "  ${DIM}Note: GitHub Pages CDN may cache old content for up to 10 minutes.${RESET}\n"
    printf "  ${DIM}If the browser shows stale content, clear site data or use incognito.${RESET}\n"
    printf "\n"
    exit 0
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Unknown Command Guard                                               │
# └─────────────────────────────────────────────────────────────────────┘

# If the first argument doesn't match any known command and also doesn't look
# like a valid version string, warn the user early.
# Version strings must contain a digit or dot (e.g., "1.6.0") or be
# literally "main" or "latest".
KNOWN_COMMANDS="clean|preview|export|deploy"
if [[ -n "${1:-}" ]] && [[ ! "${1}" =~ ^($KNOWN_COMMANDS)$ ]] && \
   [[ ! "${1}" =~ [0-9.] ]] && [[ "${1}" != "main" ]] && [[ "${1}" != "latest" ]]; then
    print_error "Unknown command or invalid version: '${1}'. Run without arguments for usage."
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Configuration                                                       │
# └─────────────────────────────────────────────────────────────────────┘

# Documentation version — determines the URL hosting path: /FlyHUD/<VERSION>/
VERSION="${1:-main}"

# Xcode build settings
SCHEME="Example iOS"
WORKSPACE="FlyHUD.xcworkspace"

# Output directories (under .build/ which is git-ignored)
DERIVED_DATA=".build/docbuild"
OUTPUT_DIR=".build/docs"

# DocC hosting configuration
HOSTING_BASE_PATH="/FlyHUD/${VERSION}"
LANDING_PAGE_NAME="FlyHUD"

# Total steps for progress counter
TOTAL_STEPS=4

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Simulator Detection                                                 │
# └─────────────────────────────────────────────────────────────────────┘

# Determine the Xcode destination for docbuild.
# If a second argument is provided, use it verbatim.
# Otherwise, auto-detect the first available iPhone simulator and
# pin arch=arm64 to avoid the "multiple matching destinations" warning.
if [[ -n "${2:-}" ]]; then
    DESTINATION="$2"
else
    DEVICE=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed 's/^[[:space:]]*//' | sed -E 's/ \([0-9A-F]{8}-[0-9A-F]{4}-.*$//')
    if [[ -z "$DEVICE" ]]; then
        print_error "No available iPhone simulator found. Install one via Xcode > Settings > Platforms."
    fi
    DESTINATION="platform=iOS Simulator,name=${DEVICE},arch=arm64"
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Build Pipeline                                                      │
# └─────────────────────────────────────────────────────────────────────┘

print_header "FlyHUD Documentation Build"
printf "\n"
print_info "Version:" "${BOLD}${VERSION}${RESET}"
print_info "Scheme:" "${SCHEME}"
print_info "Destination:" "${DESTINATION}"
print_info "Output:" "${OUTPUT_DIR}/FlyHUD.doccarchive"
print_info "Base Path:" "${HOSTING_BASE_PATH}"

# ── Step 1: Clean previous build artifacts ────────────────────────────
print_step 1 "Cleaning previous build artifacts"

rm -rf "${DERIVED_DATA}" "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"
print_success "Clean complete"

# ── Step 2: Build documentation via xcodebuild ────────────────────────
print_step 2 "Building documentation with xcodebuild"
printf "       ${DIM}This may take a minute...${RESET}\n"

BUILD_LOG="${DERIVED_DATA}/docbuild.log"
mkdir -p "${DERIVED_DATA}"
set +e
xcodebuild docbuild \
    -workspace "${WORKSPACE}" \
    -scheme "${SCHEME}" \
    -derivedDataPath "${DERIVED_DATA}" \
    -destination "${DESTINATION}" \
    DOCC_HOSTING_BASE_PATH="${HOSTING_BASE_PATH}" \
    -quiet 2>&1 | tee "${BUILD_LOG}" | grep -v "appintentsmetadataprocessor\|Metadata extraction\|No valid content was found\|top-level directive" > /dev/null
BUILD_EXIT=${PIPESTATUS[0]}
set -e

# Extract and display errors and warnings (excluding known noise)
ISSUES=$(grep -iE "error:|warning:" "${BUILD_LOG}" 2>/dev/null \
    | grep -v "appintentsmetadataprocessor\|Metadata extraction\|No valid content was found\|top-level directive" \
    || true)

if [[ $BUILD_EXIT -ne 0 ]]; then
    if [[ -n "$ISSUES" ]]; then
        print_issues "$ISSUES"
    fi
    print_error "xcodebuild docbuild failed (exit code ${BUILD_EXIT}). See above or ${BUILD_LOG}"
fi

# Show warnings even on success
if [[ -n "$ISSUES" ]]; then
    WARN_COUNT=$(echo "$ISSUES" | wc -l | tr -d ' ')
    print_issues "$ISSUES"
    print_warn "${WARN_COUNT} warning(s) found (see above)"
else
    print_success "Documentation built successfully (no warnings)"
fi

# ── Step 3: Locate generated doccarchives ─────────────────────────────
print_step 3 "Locating generated doccarchives"

ARCHIVES_DIR="${DERIVED_DATA}/Build/Products/Debug-iphonesimulator"

# Expected archives listed in merge order (FlyHUD first — contains articles)
ARCHIVES=(
    "FlyHUD.doccarchive"
    "FlyIndicatorHUD.doccarchive"
    "FlyProgressHUD.doccarchive"
    "FlyHUDSwiftUI.doccarchive"
)

ARCHIVE_PATHS=()
for archive in "${ARCHIVES[@]}"; do
    path="${ARCHIVES_DIR}/${archive}"
    if [[ -d "$path" ]]; then
        ARCHIVE_PATHS+=("$path")
        print_success "Found ${BOLD}${archive}${RESET}"
    else
        print_warn "Not found: ${archive} (skipping)"
    fi
done

if [[ ${#ARCHIVE_PATHS[@]} -eq 0 ]]; then
    print_error "No doccarchives found in ${ARCHIVES_DIR}"
fi

# ── Step 4: Merge archives into combined documentation ────────────────
print_step 4 "Merging ${#ARCHIVE_PATHS[@]} doccarchives"

if [[ ${#ARCHIVE_PATHS[@]} -eq 1 ]]; then
    # Single archive — copy directly without merge
    cp -R "${ARCHIVE_PATHS[0]}" "${OUTPUT_DIR}/FlyHUD.doccarchive"
    print_success "Copied single archive"
else
    # Multiple archives — merge with a synthesized landing page
    xcrun docc merge \
        "${ARCHIVE_PATHS[@]}" \
        --output-path "${OUTPUT_DIR}/FlyHUD.doccarchive" \
        --synthesized-landing-page-name "${LANDING_PAGE_NAME}" \
        --synthesized-landing-page-kind "Package" \
        --synthesized-landing-page-topics-style "detailedGrid"
    print_success "Merged into combined archive"
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Summary                                                             │
# └─────────────────────────────────────────────────────────────────────┘

printf "\n"
printf "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}\n"
printf "  ${GREEN}${BOLD}║${RESET}  ${GREEN}${BOLD}✓ Build complete!${RESET}\n"
printf "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"
printf "\n"
print_info "Archive:" "${OUTPUT_DIR}/FlyHUD.doccarchive"
print_info "Modules:" "${#ARCHIVE_PATHS[@]} frameworks merged"
printf "\n"
printf "  ${BOLD}Preview in browser:${RESET}\n"
printf "  ${DIM}\$ ./scripts/build-docs.sh preview${RESET}\n"
printf "\n"
printf "  ${BOLD}Preview in Xcode:${RESET}\n"
printf "  ${DIM}\$ open ${OUTPUT_DIR}/FlyHUD.doccarchive${RESET}\n"
printf "\n"
printf "  ${BOLD}Generate static site:${RESET}\n"
printf "  ${DIM}\$ ./scripts/build-docs.sh export${RESET}\n"
printf "\n"
printf "  ${BOLD}Deploy to GitHub Pages:${RESET}\n"
printf "  ${DIM}\$ ./scripts/build-docs.sh deploy${RESET}\n"
printf "\n"
