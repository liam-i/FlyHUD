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

| File | Type | Used In |
| ---- | ---- | ------- |
| `architecture.mmd` | Flowchart | overview.md |
| `view-hierarchy.mmd` | Flowchart | overview.md |
| `lifecycle.mmd` | State | overview.md |
| `sequence.mmd` | Sequence | overview.md |
| `basic-lifecycle.mmd` | State | basic-features.md |
| `content-layout.mmd` | Flowchart | basic-features.md |
| `animation-states.mmd` | State | advanced-features.md |
| `grace-time.mmd` | Sequence | advanced-features.md |
| `activity-count.mmd` | State | advanced-features.md |
| `custom-protocols.mmd` | Class | custom-ui.md |
| `custom-indicator-decision.mmd` | Flowchart | custom-ui.md |
| `testing-mock.mmd` | Class | testing.md |
| `testing-strategy.mmd` | Flowchart | testing.md |
| `best-practices-lifecycle.mmd` | Sequence | best-practices.md |
| `error-handling-states.mmd` | State | best-practices.md |

### Supported Diagram Types

| Type | Use Case | Mermaid Keyword |
| ---- | -------- | --------------- |
| Flowchart | Decision trees, layouts, architecture | `flowchart TD/LR/TB` |
| Sequence | Temporal interactions, API call flows | `sequenceDiagram` |
| State | Lifecycle, status transitions | `stateDiagram-v2` |
| Class | Protocol hierarchies, relationships | `classDiagram` |

### Mermaid Syntax Tips

- Avoid `:` in `note` text (causes parse errors) — use alternative phrasing
- In `sequenceDiagram`, don't `deactivate` the same participant in multiple `alt` branches
- Use `direction TB/LR` inside subgraphs to control layout
- Style nodes: `style NodeId fill:#color,stroke:#color`
- Link styles: `A --> B` (arrow), `A --- B` (line), `A -.-> B` (dashed)

## Writing Guidelines

### Tone & Structure

- Start each article with a one-line description (after the `#` title)
- Use `##` for major sections, `###` for subsections
- Include code examples for every API being documented
- Use tables for property/method references
- Use `> Note:`, `> Important:`, `> Warning:` for callouts

### Code Examples

- Always include `import FlyHUD` (or relevant module) at the top of the first code block
- Use `// ...` to indicate omitted code
- Show both simple and advanced usage patterns
- Include both setup and cleanup (`show` and `hide`)

### When to Add a Diagram

Add a diagram when:
- Explaining state transitions or lifecycles
- Showing protocol/class relationships
- Illustrating timing/sequencing of events
- Presenting decision trees for choosing approaches
- Visualizing view hierarchy or layout structure
