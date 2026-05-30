#!/bin/bash
#
# build.sh — Build, clean, and test FlyHUD across all schemes and platforms
#
# This script provides a unified interface for building FlyHUD using both
# xcodebuild (Xcode workspace) and swift build (Swift Package Manager).
# It supports all schemes defined in FlyHUD.xcworkspace and all target
# platforms (iOS, tvOS, visionOS).
#
# Usage:
#   ./scripts/build.sh [command] [arguments...]
#
# Commands:
#   build [scheme] [platform]   Build scheme(s) for a platform (default: all frameworks, iOS)
#   clean [scheme]              Clean build artifacts for a scheme (default: all)
#   test [scope] [platform]    Run tests (default: unit tests, iOS)
#                              Scope: "unit", "ui", "all", or a specific
#                              test class/method (e.g., "HUDTests/testShow")
#   swift [configuration]       Build via Swift Package Manager (default: debug)
#   all                         Build all framework + example schemes for ALL platforms
#   list                        Show available schemes and platforms
#   help, --help, -h            Show this usage information
#
# Arguments:
#   scheme        Scheme name. Use `list` to see available schemes.
#                 Special values:
#                   "frameworks"  — All library frameworks (FlyHUD, FlyIndicatorHUD,
#                                   FlyProgressHUD, FlyHUDSwiftUI)
#                   "examples"    — All example apps (Example iOS, Example SwiftUI,
#                                   Example tvOS)
#   platform      Target platform. One of:
#                   ios, ios-device, tvos, tvos-device,
#                   visionos, visionos-device, all, all-device
#                 (default: ios)
#   configuration For `swift` command: "debug" or "release" (default: debug)
#
# Examples:
#   ./scripts/build.sh                              # Build all frameworks for iOS
#   ./scripts/build.sh build "Example iOS"          # Build Example iOS app
#   ./scripts/build.sh build FlyHUD tvos            # Build FlyHUD framework for tvOS
#   ./scripts/build.sh build FlyHUD ios-device      # Build FlyHUD for real device arch
#   ./scripts/build.sh build frameworks all         # Build all frameworks, all sim platforms
#   ./scripts/build.sh build frameworks all-device  # Build all frameworks, all device archs
#   ./scripts/build.sh build examples               # Build all example apps
#   ./scripts/build.sh clean                        # Clean all schemes
#   ./scripts/build.sh clean FlyHUD                 # Clean specific scheme
#   ./scripts/build.sh test                         # Run all unit tests (iOS)
#   ./scripts/build.sh test unit                    # Run all unit tests (explicit)
#   ./scripts/build.sh test ui                      # Run all UI/E2E tests
#   ./scripts/build.sh test all                     # Run both unit + UI tests
#   ./scripts/build.sh test HUDTests                # Run only HUDTests class
#   ./scripts/build.sh test HUDTests/testBasicShow  # Run single test method
#   ./scripts/build.sh test HUDStressTests          # Run stress tests only
#   ./scripts/build.sh test HUDAccessibilityUITests # Run accessibility UI tests
#   ./scripts/build.sh test unit ios                # Unit tests on iOS (explicit platform)
#   ./scripts/build.sh swift                        # SPM debug build
#   ./scripts/build.sh swift release                # SPM release build
#   ./scripts/build.sh all                          # Build everything, all platforms
#   ./scripts/build.sh list                         # Show available schemes/platforms
#
# Test Command Details:
#   The `test` command supports flexible test selection:
#
#   Scope (first argument after "test"):
#     unit              Run all unit/integration tests ("Example Tests" scheme)
#     ui                Run all end-to-end UI tests ("Example UITests" scheme)
#     all               Run both unit tests AND UI tests sequentially
#     <ClassName>       Run all tests in a specific XCTestCase class
#     <Class/method>    Run a single test method
#
#   Platform (second argument, optional):
#     ios (default) — only ios is supported for test schemes
#
#   Test target detection:
#     - Class names containing "UITest" → routed to "Example UITests" scheme
#     - All other class names → routed to "Example Tests" scheme
#
#   Filter syntax (maps to xcodebuild -only-testing:):
#     "HUDTests"                    → -only-testing:"Example Tests/HUDTests"
#     "HUDTests/testBasicShow"      → -only-testing:"Example Tests/HUDTests/testBasicShow"
#     "HUDAccessibilityUITests"     → -only-testing:"UITests/HUDAccessibilityUITests"
#
#   Available test classes (unit):
#     HUDTests, HUDStressTests, HUDExtendedTests, ModelTests,
#     ContentViewTests, BackgroundViewTests, BaseViewTests, ButtonTests,
#     LabelTests, DisplayLinkTests, KeyboardObserverTests, UnfairLockTests,
#     ExtensionsTests, ActivityIndicatorViewTests, ProgressViewTests,
#     SwiftUIHUDTests, SwiftUIHUDIntegrationTests, SwiftUIHUDStressTests,
#     RotateViewableTests, ProgressViewableTests, ActivityIndicatorViewableTests
#
#   Available test classes (UI):
#     HUDUITests, HUDAccessibilityUITests,
#     IndicatorHUDUITests, ProgressHUDUITests, SwiftUIHUDUITests
#
# Supported Platforms:
#   ios           — iOS Simulator (auto-detects first available iPhone)
#   ios-device    — iOS device (generic, no real device needed)
#   tvos          — tvOS Simulator (auto-detects first available Apple TV)
#   tvos-device   — tvOS device (generic, no real device needed)
#   visionos      — visionOS Simulator (Apple Vision Pro)
#   visionos-device — visionOS device (generic, no real device needed)
#   all           — All simulator platforms supported by the scheme
#   all-device    — All device (generic) platforms supported by the scheme
#
# Configuration:
#   Build configuration is always Debug for xcodebuild (faster iteration).
#   Code signing is disabled (CODE_SIGNING_ALLOWED=NO) for CI compatibility.
#
# Prerequisites:
#   - Xcode 15.0+ with iOS, tvOS, and/or visionOS simulator runtimes
#   - Swift 5.9+ toolchain (for `swift` command)
#   - Must be run from the repository root (where FlyHUD.xcworkspace resides)
#   - Uses the Xcode selected via `xcode-select` (or DEVELOPER_DIR if set)
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

BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
CYAN=$'\033[36m'
RED=$'\033[31m'
MAGENTA=$'\033[35m'

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

# Print a numbered step
print_step() {
    printf "\n  ${CYAN}${BOLD}[%s/%s]${RESET} %s\n" "$1" "$TOTAL_STEPS" "$2"
}

# Print a success line
print_success() {
    printf "       ${GREEN}✓${RESET} %s\n" "$1"
}

# Print a warning line
print_warn() {
    printf "       ${YELLOW}⚠${RESET} %s\n" "$1"
}

# Print an error message and exit
print_error() {
    printf "\n  ${RED}${BOLD}✗ Error:${RESET} %s\n\n" "$1" >&2
    exit 1
}

# Print a key-value info line
print_info() {
    printf "       ${DIM}%-14s${RESET} %s\n" "$1" "$2"
}

# Print a build result line (scheme + platform + status)
print_result() {
    local scheme="$1" platform="$2" status="$3" duration="$4"
    if [[ "$status" == "success" ]]; then
        printf "       ${GREEN}✓${RESET} %-24s ${DIM}%-10s${RESET} ${DIM}(%s)${RESET}\n" "$scheme" "$platform" "$duration"
    else
        printf "       ${RED}✗${RESET} %-24s ${DIM}%-10s${RESET} ${RED}FAILED${RESET}\n" "$scheme" "$platform"
    fi
}

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Constants                                                           │
# └─────────────────────────────────────────────────────────────────────┘

# Workspace file
WORKSPACE="FlyHUD.xcworkspace"

# All available schemes grouped by type
FRAMEWORK_SCHEMES=("FlyHUD" "FlyIndicatorHUD" "FlyProgressHUD" "FlyHUDSwiftUI")
EXAMPLE_SCHEMES=("Example iOS" "Example SwiftUI" "Example tvOS")
TEST_SCHEMES=("Example Tests" "Example UITests")
# ALL_SCHEMES excludes TEST_SCHEMES — test targets can't be built with the
# "build" action; use the "test" subcommand instead.
ALL_SCHEMES=("${FRAMEWORK_SCHEMES[@]}" "${EXAMPLE_SCHEMES[@]}")

# Platform-to-scheme compatibility map
# Each scheme has a list of supported platforms
# Variable naming: PLATFORMS_<Scheme_Name_With_Underscores>="platform1 platform2 ..."
declare_platform_support() {
    # Library frameworks support all platforms
    PLATFORMS_FlyHUD="ios tvos visionos"
    PLATFORMS_FlyIndicatorHUD="ios tvos visionos"
    PLATFORMS_FlyProgressHUD="ios tvos visionos"
    PLATFORMS_FlyHUDSwiftUI="ios tvos visionos"
    # Example apps are platform-specific
    PLATFORMS_Example_iOS="ios"
    PLATFORMS_Example_SwiftUI="ios visionos"
    PLATFORMS_Example_tvOS="tvos"
    PLATFORMS_Example_Tests="ios"
    PLATFORMS_Example_UITests="ios"
}
declare_platform_support

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Platform Resolution                                                 │
# └─────────────────────────────────────────────────────────────────────┘

# Resolve a platform keyword to an xcodebuild destination string.
# Auto-detects the first available simulator for simulator platforms.
# Uses generic destinations for device platforms (no real device needed).
# Results are cached to avoid repeated calls to `xcrun simctl list`.
#
# Arguments:
#   $1 — Platform keyword: "ios", "ios-device", "tvos", "tvos-device",
#         "visionos", or "visionos-device"
#
# Output:
#   Prints the destination string to stdout.
#   Exits with error if no simulator is available (for sim platforms).
_DEST_CACHE_ios=""
_DEST_CACHE_tvos=""
_DEST_CACHE_visionos=""

resolve_destination() {
    local platform="$1"
    case "$platform" in
        ios)
            if [[ -n "$_DEST_CACHE_ios" ]]; then
                echo "$_DEST_CACHE_ios"
                return
            fi
            local device
            device=$(xcrun simctl list devices available | grep "iPhone" | head -1 \
                | sed 's/^[[:space:]]*//' | sed -E 's/ \([0-9A-F]{8}-[0-9A-F]{4}-.*$//')
            if [[ -z "$device" ]]; then
                print_error "No available iPhone simulator. Install via Xcode > Settings > Platforms."
            fi
            _DEST_CACHE_ios="platform=iOS Simulator,name=${device},arch=arm64"
            echo "$_DEST_CACHE_ios"
            ;;
        ios-device)
            echo "generic/platform=iOS"
            ;;
        tvos)
            if [[ -n "$_DEST_CACHE_tvos" ]]; then
                echo "$_DEST_CACHE_tvos"
                return
            fi
            local device
            device=$(xcrun simctl list devices available | grep "Apple TV" | head -1 \
                | sed 's/^[[:space:]]*//' | sed -E 's/ \([0-9A-F]{8}-[0-9A-F]{4}-.*$//')
            if [[ -z "$device" ]]; then
                print_error "No available Apple TV simulator. Install via Xcode > Settings > Platforms."
            fi
            _DEST_CACHE_tvos="platform=tvOS Simulator,name=${device}"
            echo "$_DEST_CACHE_tvos"
            ;;
        tvos-device)
            echo "generic/platform=tvOS"
            ;;
        visionos)
            if [[ -n "$_DEST_CACHE_visionos" ]]; then
                echo "$_DEST_CACHE_visionos"
                return
            fi
            local device
            device=$(xcrun simctl list devices available | grep "Apple Vision" | head -1 \
                | sed 's/^[[:space:]]*//' | sed -E 's/ \([0-9A-F]{8}-[0-9A-F]{4}-.*$//')
            if [[ -z "$device" ]]; then
                print_error "No available visionOS simulator. Install via Xcode > Settings > Platforms."
            fi
            _DEST_CACHE_visionos="platform=visionOS Simulator,name=${device},arch=arm64"
            echo "$_DEST_CACHE_visionos"
            ;;
        visionos-device)
            echo "generic/platform=visionOS"
            ;;
        *)
            print_error "Unknown platform: '${platform}'. Valid: ios, ios-device, tvos, tvos-device, visionos, visionos-device"
            ;;
    esac
}

# Get the list of supported platforms for a scheme.
#
# Arguments:
#   $1 — Scheme name (e.g., "FlyHUD", "Example iOS")
#
# Output:
#   Prints space-separated platform list to stdout.
get_scheme_platforms() {
    local scheme="$1"
    # Normalize scheme name: replace spaces with underscore
    local normalized="${scheme// /_}"
    local var_name="PLATFORMS_${normalized}"
    echo "${!var_name:-ios}"
}

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Build Execution                                                     │
# └─────────────────────────────────────────────────────────────────────┘

# Execute xcodebuild with standard settings.
#
# Arguments:
#   $1 — Action: "build", "clean", or "test"
#   $2 — Scheme name
#   $3 — Destination string
#   $4 — (optional) Log file path; defaults to /dev/null (discard output)
#
# Returns:
#   0 on success, non-zero on failure
run_xcodebuild() {
    local action="$1" scheme="$2" destination="$3"
    local log_file="${4:-/dev/null}"

    xcodebuild "$action" \
        -workspace "${WORKSPACE}" \
        -scheme "$scheme" \
        -destination "$destination" \
        -configuration Debug \
        CODE_SIGNING_ALLOWED=NO \
        -quiet > "$log_file" 2>&1

    return $?
}

# Build a single scheme for a single platform, with timing.
# Captures build output to .build/logs/ and displays errors/warnings on failure.
#
# Arguments:
#   $1 — Scheme name
#   $2 — Platform keyword (ios, tvos, visionos, ios-device, tvos-device, visionos-device)
#
# Returns:
#   0 on success, 1 on failure
# Side effects:
#   Prints result line. Increments PASS_COUNT or FAIL_COUNT.
build_scheme_platform() {
    local scheme="$1" platform="$2"
    local destination
    destination=$(resolve_destination "$platform")

    # Create log directory and file for capturing build output
    local log_dir=".build/logs"
    local log_file="${log_dir}/${scheme// /_}_${platform}.log"
    mkdir -p "$log_dir"

    local start_time end_time duration
    start_time=$(date +%s)

    set +e
    run_xcodebuild "build" "$scheme" "$destination" "$log_file"
    local exit_code=$?
    set -e

    end_time=$(date +%s)
    duration="$((end_time - start_time))s"

    if [[ $exit_code -eq 0 ]]; then
        print_result "$scheme" "$platform" "success" "$duration"
        PASS_COUNT=$((PASS_COUNT + 1))

        # Show warnings even on success
        local warnings
        warnings=$(grep -i "warning:" "$log_file" 2>/dev/null \
            | grep -v "appintentsmetadataprocessor\|Metadata extraction\|multiple matching destinations" || true)
        if [[ -n "$warnings" ]]; then
            local warn_count
            warn_count=$(echo "$warnings" | wc -l | tr -d ' ')
            printf "       ${YELLOW}⚠${RESET} ${DIM}%s warning(s) — see %s${RESET}\n" "$warn_count" "$log_file"
        fi
    else
        print_result "$scheme" "$platform" "failed" ""
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_ITEMS+=("${scheme} (${platform})")

        # Display errors and warnings from log
        local issues
        issues=$(grep -iE "error:|warning:" "$log_file" 2>/dev/null \
            | grep -v "appintentsmetadataprocessor\|Metadata extraction\|multiple matching destinations" \
            | head -20 || true)
        if [[ -n "$issues" ]]; then
            shopt -s nocasematch
            while IFS= read -r line; do
                if [[ "$line" == *"error:"* ]]; then
                    printf "         ${RED}%s${RESET}\n" "$line"
                else
                    printf "         ${YELLOW}%s${RESET}\n" "$line"
                fi
            done <<< "$issues"
            shopt -u nocasematch
            printf "       ${DIM}Full log: %s${RESET}\n" "$log_file"
        fi
    fi

    return $exit_code
}

# ┌─────────────────────────────────────────────────────────────────────┐
# │ List Command                                                        │
# └─────────────────────────────────────────────────────────────────────┘

if [[ "${1:-}" == "list" ]]; then
    print_header "FlyHUD Build — Available Targets"

    printf "\n  ${BOLD}Library Frameworks:${RESET}\n"
    for scheme in "${FRAMEWORK_SCHEMES[@]}"; do
        platforms=$(get_scheme_platforms "$scheme")
        printf "       ${GREEN}◆${RESET} %-24s ${DIM}[%s]${RESET}\n" "$scheme" "$platforms"
    done

    printf "\n  ${BOLD}Example Apps:${RESET}\n"
    for scheme in "${EXAMPLE_SCHEMES[@]}"; do
        platforms=$(get_scheme_platforms "$scheme")
        printf "       ${CYAN}◆${RESET} %-24s ${DIM}[%s]${RESET}\n" "$scheme" "$platforms"
    done

    printf "\n  ${BOLD}Test Targets:${RESET}\n"
    for scheme in "${TEST_SCHEMES[@]}"; do
        platforms=$(get_scheme_platforms "$scheme")
        printf "       ${MAGENTA}◆${RESET} %-24s ${DIM}[%s]${RESET}\n" "$scheme" "$platforms"
    done

    printf "\n  ${BOLD}Platforms:${RESET}\n"
    printf "       ${DIM}ios${RESET}             — iOS Simulator (auto-detect iPhone)\n"
    printf "       ${DIM}ios-device${RESET}      — iOS device (generic, no real device needed)\n"
    printf "       ${DIM}tvos${RESET}            — tvOS Simulator (auto-detect Apple TV)\n"
    printf "       ${DIM}tvos-device${RESET}     — tvOS device (generic, no real device needed)\n"
    printf "       ${DIM}visionos${RESET}        — visionOS Simulator (Apple Vision Pro)\n"
    printf "       ${DIM}visionos-device${RESET} — visionOS device (generic, no real device needed)\n"
    printf "       ${DIM}all${RESET}             — All simulator platforms for the scheme\n"
    printf "       ${DIM}all-device${RESET}      — All device platforms for the scheme\n"

    printf "\n  ${BOLD}Scheme Groups:${RESET}\n"
    printf "       ${DIM}frameworks${RESET} — All library frameworks\n"
    printf "       ${DIM}examples${RESET}   — All example apps\n"

    printf "\n  ${BOLD}Xcode:${RESET}\n"
    printf "       ${DIM}%s${RESET}\n" "$(xcode-select -p 2>/dev/null || echo 'Not found')"
    printf "       ${DIM}%s${RESET}\n" "$(swift --version 2>/dev/null | head -1)"
    printf "\n"
    exit 0
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Clean Command                                                       │
# └─────────────────────────────────────────────────────────────────────┘

if [[ "${1:-}" == "clean" ]]; then
    SCHEME_ARG="${2:-}"

    # Determine which schemes to clean
    # Note: Test schemes are excluded from default clean because they share
    # build products with "Example iOS" — cleaning them is redundant.
    if [[ -z "$SCHEME_ARG" ]]; then
        CLEAN_SCHEMES=("${ALL_SCHEMES[@]}")
        HEADER_SUFFIX="all schemes"
    elif [[ "$SCHEME_ARG" == "frameworks" ]]; then
        CLEAN_SCHEMES=("${FRAMEWORK_SCHEMES[@]}")
        HEADER_SUFFIX="frameworks"
    elif [[ "$SCHEME_ARG" == "examples" ]]; then
        CLEAN_SCHEMES=("${EXAMPLE_SCHEMES[@]}")
        HEADER_SUFFIX="examples"
    else
        CLEAN_SCHEMES=("$SCHEME_ARG")
        HEADER_SUFFIX="$SCHEME_ARG"
    fi

    TOTAL_STEPS=${#CLEAN_SCHEMES[@]}
    print_header "FlyHUD Clean — ${HEADER_SUFFIX}"

    STEP=0
    CLEANED=0
    for scheme in "${CLEAN_SCHEMES[@]}"; do
        STEP=$((STEP + 1))
        print_step $STEP "Cleaning ${scheme}"

        # Use generic destination matching the scheme's first supported platform
        local_platforms=$(get_scheme_platforms "$scheme")
        local_first_platform="${local_platforms%% *}"
        case "$local_first_platform" in
            tvos)     CLEAN_DEST="generic/platform=tvOS Simulator" ;;
            visionos) CLEAN_DEST="generic/platform=visionOS Simulator" ;;
            *)        CLEAN_DEST="generic/platform=iOS Simulator" ;;
        esac

        set +e
        run_xcodebuild "clean" "$scheme" "$CLEAN_DEST"
        CLEAN_EXIT=$?
        set -e

        if [[ $CLEAN_EXIT -eq 0 ]]; then
            print_success "Cleaned"
            CLEANED=$((CLEANED + 1))
        else
            print_warn "Clean may have partially failed — see xcodebuild output"
        fi
    done

    # Remove DerivedData directory (fixes corrupted build database issues)
    while IFS= read -r dd_dir; do
        rm -rf "$dd_dir"
        print_success "Removed DerivedData: $(basename "$dd_dir")"
        CLEANED=$((CLEANED + 1))
    done < <(find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -name "FlyHUD-*" -type d 2>/dev/null)

    # Remove local build logs
    if [[ -d ".build/logs" ]]; then
        rm -rf ".build/logs"
        print_success "Removed .build/logs/"
        CLEANED=$((CLEANED + 1))
    fi

    printf "\n"
    printf "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}\n"
    printf "  ${GREEN}${BOLD}║${RESET}  ${GREEN}${BOLD}✓ Clean complete!${RESET}\n"
    printf "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"
    printf "\n"
    print_info "Cleaned:" "${CLEANED} items"
    printf "\n"
    exit 0
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Swift Build Command                                                 │
# └─────────────────────────────────────────────────────────────────────┘

if [[ "${1:-}" == "swift" ]]; then
    CONFIG="${2:-debug}"

    # Validate configuration
    if [[ "$CONFIG" != "debug" && "$CONFIG" != "release" ]]; then
        print_error "Invalid configuration: '${CONFIG}'. Use 'debug' or 'release'."
    fi

    # Swift build requires cross-compilation for iOS-only packages.
    # Use --triple and --sdk to target the iOS Simulator.
    IOS_SDK=$(xcrun --show-sdk-path --sdk iphonesimulator 2>/dev/null) || \
        print_error "iOS Simulator SDK not found. Install via Xcode > Settings > Platforms."
    TRIPLE="arm64-apple-ios13.0-simulator"

    TOTAL_STEPS=1
    print_header "FlyHUD Swift Package Manager Build"
    printf "\n"
    print_info "Configuration:" "${CONFIG}"
    print_info "Toolchain:" "$(swift --version 2>/dev/null | head -1)"
    print_info "Triple:" "${TRIPLE}"
    print_info "SDK:" "$(echo "$IOS_SDK" | sed 's|.*/SDKs/||')"

    print_step 1 "Building with swift build"
    printf "       ${DIM}This may take a moment...${RESET}\n"

    # Capture full output to log; show last 5 lines during build
    SWIFT_LOG_DIR=".build/logs"
    SWIFT_LOG_FILE="${SWIFT_LOG_DIR}/swift_${CONFIG}.log"
    mkdir -p "$SWIFT_LOG_DIR"

    local_start=$(date +%s)
    set +e
    swift build \
        --triple "$TRIPLE" \
        --sdk "$IOS_SDK" \
        -c "$CONFIG" > "$SWIFT_LOG_FILE" 2>&1
    BUILD_EXIT=$?
    set -e
    local_end=$(date +%s)
    local_duration="$((local_end - local_start))s"

    if [[ $BUILD_EXIT -ne 0 ]]; then
        # Show last 20 lines of errors for immediate diagnosis
        tail -20 "$SWIFT_LOG_FILE" | while IFS= read -r line; do
            printf "       ${RED}%s${RESET}\n" "$line"
        done
        printf "       ${DIM}Full log: %s${RESET}\n" "$SWIFT_LOG_FILE"
        print_error "swift build failed (exit code ${BUILD_EXIT})"
    fi

    printf "\n"
    printf "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}\n"
    printf "  ${GREEN}${BOLD}║${RESET}  ${GREEN}${BOLD}✓ Swift build complete!${RESET}\n"
    printf "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"
    printf "\n"
    print_info "Configuration:" "${CONFIG}"
    print_info "Duration:" "${local_duration}"
    printf "\n"
    exit 0
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Test Command                                                        │
# └─────────────────────────────────────────────────────────────────────┘

# Handle "test" subcommand — see top-of-file comments for full documentation.
if [[ "${1:-}" == "test" ]]; then
    TEST_ARG="${2:-unit}"
    TEST_PLATFORM="${3:-ios}"

    # Determine test scope and filter
    TEST_FILTER=""
    case "$TEST_ARG" in
        unit)
            # All unit tests
            TEST_SCHEMES_TO_RUN=("Example Tests")
            TEST_SCOPE="Unit Tests"
            ;;
        ui)
            # All UI tests (end-to-end)
            TEST_SCHEMES_TO_RUN=("Example UITests")
            TEST_SCOPE="UI Tests"
            ;;
        all)
            # Both unit and UI tests
            TEST_SCHEMES_TO_RUN=("Example Tests" "Example UITests")
            TEST_SCOPE="All Tests (Unit + UI)"
            ;;
        *)
            # Specific test class or method — could be in either target
            # Format: "ClassName" or "ClassName/methodName"
            TEST_FILTER="$TEST_ARG"
            TEST_PLATFORM="${3:-ios}"

            # Determine which scheme the test belongs to:
            # UI tests contain "UITest" in name, everything else is unit tests
            if [[ "$TEST_FILTER" == *UITest* ]]; then
                TEST_SCHEMES_TO_RUN=("Example UITests")
                TEST_SCOPE="UI Test: ${TEST_FILTER}"
            else
                TEST_SCHEMES_TO_RUN=("Example Tests")
                TEST_SCOPE="Unit Test: ${TEST_FILTER}"
            fi
            ;;
    esac

    TOTAL_STEPS=${#TEST_SCHEMES_TO_RUN[@]}
    DESTINATION=$(resolve_destination "$TEST_PLATFORM")

    print_header "FlyHUD Test — ${TEST_SCOPE}"
    printf "\n"
    print_info "Scope:" "${TEST_SCOPE}"
    print_info "Platform:" "${TEST_PLATFORM}"
    print_info "Destination:" "${DESTINATION}"
    if [[ -n "$TEST_FILTER" ]]; then
        print_info "Filter:" "${TEST_FILTER}"
    fi

    # Validate platform against test scheme support
    local_base="${TEST_PLATFORM%-device}"
    for TEST_SCHEME_CHECK in "${TEST_SCHEMES_TO_RUN[@]}"; do
        supported=$(get_scheme_platforms "$TEST_SCHEME_CHECK")
        if ! echo "$supported" | grep -qw "$local_base"; then
            print_error "'${TEST_SCHEME_CHECK}' only supports [${supported}], not '${TEST_PLATFORM}'."
        fi
    done

    # Run tests for each scheme
    STEP=0
    OVERALL_EXIT=0
    for TEST_SCHEME in "${TEST_SCHEMES_TO_RUN[@]}"; do
        STEP=$((STEP + 1))
        print_step $STEP "Running ${TEST_SCHEME}"
        printf "       ${DIM}This may take a minute...${RESET}\n"

        # Build the xcodebuild command with optional -only-testing: filter
        TEST_CMD=(xcodebuild test
            -workspace "${WORKSPACE}"
            -scheme "$TEST_SCHEME"
            -destination "$DESTINATION"
            -configuration Debug
            CODE_SIGNING_ALLOWED=NO)

        # Add test filter if specified
        if [[ -n "$TEST_FILTER" ]]; then
            # Determine the bundle name for -only-testing: prefix
            if [[ "$TEST_SCHEME" == "Example UITests" ]]; then
                TEST_CMD+=(-only-testing:"UITests/${TEST_FILTER}")
            else
                TEST_CMD+=(-only-testing:"Example Tests/${TEST_FILTER}")
            fi
        fi

        # Create log for this test run
        TEST_LOG_DIR=".build/logs"
        TEST_LOG_FILE="${TEST_LOG_DIR}/test_${TEST_SCHEME// /_}.log"
        mkdir -p "$TEST_LOG_DIR"

        local_start=$(date +%s)
        set +e
        "${TEST_CMD[@]}" 2>&1 | tee "$TEST_LOG_FILE" | grep -E "Test (Suite|Case)|passed|failed|Executed|error:"
        SCHEME_EXIT=${PIPESTATUS[0]}
        set -e
        local_end=$(date +%s)
        local_duration="$((local_end - local_start))s"

        # Extract test summary from log
        TEST_SUMMARY=$(grep -E "Executed [0-9]+ test" "$TEST_LOG_FILE" 2>/dev/null | tail -1 || true)

        if [[ $SCHEME_EXIT -eq 0 ]]; then
            print_success "${TEST_SCHEME} passed (${local_duration})"
            if [[ -n "$TEST_SUMMARY" ]]; then
                printf "       ${DIM}%s${RESET}\n" "$TEST_SUMMARY"
            fi
        else
            printf "       ${RED}✗${RESET} ${TEST_SCHEME} ${RED}FAILED${RESET} (${local_duration})\n"
            OVERALL_EXIT=1

            # Show failed test details
            FAILURES=$(grep -E "failed|error:" "$TEST_LOG_FILE" 2>/dev/null \
                | grep -v "^$\|Test Suite\|Executed" | head -15 || true)
            if [[ -n "$FAILURES" ]]; then
                printf "\n"
                while IFS= read -r line; do
                    printf "         ${RED}%s${RESET}\n" "$line"
                done <<< "$FAILURES"
            fi
            printf "       ${DIM}Full log: %s${RESET}\n" "$TEST_LOG_FILE"
        fi
    done

    # Final summary
    printf "\n"
    if [[ $OVERALL_EXIT -eq 0 ]]; then
        printf "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}\n"
        printf "  ${GREEN}${BOLD}║${RESET}  ${GREEN}${BOLD}✓ All tests passed!${RESET}\n"
        printf "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"
    else
        printf "  ${RED}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}\n"
        printf "  ${RED}${BOLD}║${RESET}  ${RED}${BOLD}✗ Some tests failed!${RESET}\n"
        printf "  ${RED}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"
    fi
    printf "\n"
    print_info "Scope:" "${TEST_SCOPE}"
    if [[ -n "$TEST_FILTER" ]]; then
        print_info "Filter:" "${TEST_FILTER}"
    fi
    printf "\n"

    exit $OVERALL_EXIT
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Help & Unknown Command Guard                                        │
# └─────────────────────────────────────────────────────────────────────┘

# Show usage for --help / -h / help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "help" ]]; then
    sed -n '2,/^[^#]/{ /^#/s/^# \{0,1\}//p; }' "$0"
    exit 0
fi

# Guard against unknown commands that look like subcommands (start with a letter,
# not a valid scheme or group name). Known commands are already handled above;
# valid build targets are: scheme names, "frameworks", "examples", "all".
KNOWN_BUILD_ARGS="build|all|frameworks|examples"
KNOWN_SCHEMES=$(printf "%s|" "${ALL_SCHEMES[@]}" "${TEST_SCHEMES[@]}" | sed 's/|$//')
if [[ -n "${1:-}" && "${1:-}" != "build" ]]; then
    shopt -s nocasematch
    if [[ ! "${1:-}" =~ ^($KNOWN_BUILD_ARGS|$KNOWN_SCHEMES)$ ]]; then
        print_error "Unknown command or scheme: '${1}'. Run with --help for usage."
    fi
    shopt -u nocasematch
fi

# ┌─────────────────────────────────────────────────────────────────────┐
# │ Build Command (default)                                             │
# └─────────────────────────────────────────────────────────────────────┘

# Parse arguments for the build command.
# If first arg is "build", shift it off. Otherwise treat all args as build args.
if [[ "${1:-}" == "build" ]]; then
    shift
fi

# Handle "all" as a special case — build everything for all platforms
if [[ "${1:-}" == "all" ]]; then
    BUILD_SCHEMES=("${ALL_SCHEMES[@]}")
    PLATFORM_ARG="all"
    HEADER_SUFFIX="frameworks + examples × all platforms"
else
    SCHEME_ARG="${1:-frameworks}"
    PLATFORM_ARG="${2:-ios}"

    # Resolve scheme argument to a list of schemes
    case "$SCHEME_ARG" in
        frameworks)
            BUILD_SCHEMES=("${FRAMEWORK_SCHEMES[@]}")
            HEADER_SUFFIX="frameworks"
            ;;
        examples)
            BUILD_SCHEMES=("${EXAMPLE_SCHEMES[@]}")
            HEADER_SUFFIX="examples"
            ;;
        *)
            BUILD_SCHEMES=("$SCHEME_ARG")
            HEADER_SUFFIX="$SCHEME_ARG"
            ;;
    esac
fi

# ── Compute total build tasks ─────────────────────────────────────────

# Build a list of (scheme, platform) pairs
BUILD_TASKS=()
for scheme in "${BUILD_SCHEMES[@]}"; do
    supported=$(get_scheme_platforms "$scheme")
    if [[ "$PLATFORM_ARG" == "all" ]]; then
        # All simulator platforms
        for platform in $supported; do
            BUILD_TASKS+=("${scheme}|${platform}")
        done
    elif [[ "$PLATFORM_ARG" == "all-device" ]]; then
        # All device (generic) platforms
        for platform in $supported; do
            BUILD_TASKS+=("${scheme}|${platform}-device")
        done
    else
        # Single platform — verify compatibility (strip -device suffix for check)
        local_base="${PLATFORM_ARG%-device}"
        if echo "$supported" | grep -qw "$local_base"; then
            BUILD_TASKS+=("${scheme}|${PLATFORM_ARG}")
        else
            print_warn "Scheme '${scheme}' does not support platform '${local_base}' — skipping"
        fi
    fi
done

if [[ ${#BUILD_TASKS[@]} -eq 0 ]]; then
    print_error "No valid build tasks. Check scheme and platform arguments."
fi

TOTAL_STEPS=${#BUILD_TASKS[@]}
PASS_COUNT=0
FAIL_COUNT=0
FAILED_ITEMS=()

# ── Print header ──────────────────────────────────────────────────────

print_header "FlyHUD Build — ${HEADER_SUFFIX}"
printf "\n"
print_info "Schemes:" "${#BUILD_SCHEMES[@]}"
print_info "Tasks:" "${#BUILD_TASKS[@]} build(s)"
print_info "Platform:" "${PLATFORM_ARG}"
print_info "Config:" "Debug"
printf "\n       ${DIM}Building...${RESET}\n"

# ── Execute builds ────────────────────────────────────────────────────

BUILD_START=$(date +%s)

STEP=0
for task in "${BUILD_TASKS[@]}"; do
    STEP=$((STEP + 1))
    # Split task into scheme and platform
    scheme="${task%%|*}"
    platform="${task##*|}"

    printf "  ${CYAN}${BOLD}[%s/%s]${RESET} ${BOLD}%s${RESET} → %s\n" "$STEP" "$TOTAL_STEPS" "$scheme" "$platform"
    build_scheme_platform "$scheme" "$platform" || true
done

BUILD_END=$(date +%s)
TOTAL_DURATION="$((BUILD_END - BUILD_START))s"

# ── Summary ───────────────────────────────────────────────────────────

printf "\n"
if [[ $FAIL_COUNT -eq 0 ]]; then
    printf "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}\n"
    printf "  ${GREEN}${BOLD}║${RESET}  ${GREEN}${BOLD}✓ All builds passed!${RESET}\n"
    printf "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"
else
    printf "  ${RED}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}\n"
    printf "  ${RED}${BOLD}║${RESET}  ${RED}${BOLD}✗ Some builds failed!${RESET}\n"
    printf "  ${RED}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"
fi
printf "\n"
print_info "Passed:" "${GREEN}${PASS_COUNT}${RESET}/${#BUILD_TASKS[@]}"
print_info "Failed:" "${RED}${FAIL_COUNT}${RESET}/${#BUILD_TASKS[@]}"
print_info "Duration:" "${TOTAL_DURATION}"

if [[ $FAIL_COUNT -gt 0 ]]; then
    printf "\n  ${BOLD}Failed builds:${RESET}\n"
    for item in "${FAILED_ITEMS[@]}"; do
        printf "       ${RED}✗${RESET} %s\n" "$item"
    done
fi

printf "\n"

# Exit with failure if any build failed
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
fi
