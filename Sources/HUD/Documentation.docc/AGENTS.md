# Documentation (DocC) - AI Coding Guidelines

## Structure

```text
Sources/HUD/Documentation.docc/
├── Documentation.md            → Landing page with topic groups
├── overview.md                 → Architecture & module overview
├── getting-started.md          → Installation & first steps
├── basic-features.md           → Display modes, show/hide, labels
├── advanced-features.md        → Animation, keyboard, grace time
├── custom-ui.md                → Custom indicators & progress views
├── best-practices.md           → Lifecycle, performance, patterns
├── testing.md                  → Unit test & mock strategies
├── benchmark.md                → Performance benchmarks
├── faq.md                      → Frequently asked questions
├── privacy.md                  → Privacy manifest details
├── release-notes.md            → Version history
├── CHANGELOG.md                → Detailed changelog
└── Resources/
    ├── *.svg                   → Rendered diagram images (DO NOT edit directly)
    └── mermaid-src/*.mmd       → Mermaid source files (edit these)
```

## Article Conventions

### Image Embedding

```markdown
<!-- In overview.md and getting-started.md (top-level articles): -->
@Image(source: "architecture.svg", alt: "Description of diagram")

<!-- In all other articles: -->
![Description of diagram](filename.svg)
```

### Symbol References

```markdown
``HUD``                    → links to HUD class
``HUD/Animation``          → links to nested type
``ContentView/Mode``       → links to enum
``HUDDelegate/hudWasHidden(_:)`` → links to method
```

### Article Cross-References

```markdown
<doc:overview>
<doc:getting-started>
<doc:basic-features>
<doc:advanced-features>
<doc:custom-ui>
<doc:best-practices>
<doc:testing>
```

### Topic Groups (Documentation.md)

All articles must be listed in topic groups in `Documentation.md`. Currently:

```markdown
## Topics
### Essentials
- <doc:overview>
- <doc:getting-started>
- <doc:basic-features>
### Guides
- <doc:advanced-features>
- <doc:custom-ui>
- <doc:best-practices>
- <doc:testing>
### Reference
- <doc:benchmark>
- <doc:faq>
- <doc:privacy>
- <doc:release-notes>
```

## Diagram Workflow

### Creating a New Diagram

1. Create `.mmd` file in `Resources/mermaid-src/`:
   ```bash
   cd Sources/HUD/Documentation.docc/Resources/mermaid-src/
   # Edit your-diagram.mmd
   ```

2. Render to SVG:
   ```bash
   mmdc -i your-diagram.mmd -o ../your-diagram.svg -t neutral --backgroundColor transparent
   ```

3. Embed in article:
   ```markdown
   ![Descriptive alt text](your-diagram.svg)
   ```

### Naming Convention

Use kebab-case matching the concept:
- `grace-time.mmd` → timing behavior
- `animation-states.mmd` → state machine
- `custom-protocols.mmd` → class relationships
- `testing-mock.mmd` → test architecture

### Current Diagram Inventory

Check `Resources/mermaid-src/*.mmd` for full list. Types used: Flowchart (`flowchart TD/LR`), Sequence (`sequenceDiagram`), State (`stateDiagram-v2`), Class (`classDiagram`).

### Mermaid Syntax Tips

- Avoid `:` in `note` text (causes parse errors)
- Don't `deactivate` same participant in multiple `alt` branches
- Use `direction TB/LR` inside subgraphs
- Naming: kebab-case matching concept (e.g. `grace-time.mmd`, `animation-states.mmd`)

## Writing Guidelines

- Start each article with a one-line description after the `#` title
- Use `##` for major sections, `###` for subsections
- Include code examples for every API; always show `import FlyHUD` in first block
- Use tables for property/method references
- Use `> Note:`, `> Important:`, `> Warning:` for callouts
- Show both simple and advanced usage (setup + cleanup)
- Add diagrams for: state transitions, protocol relationships, timing/sequencing, decision trees
