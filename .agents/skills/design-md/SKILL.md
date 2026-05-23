# /design-md — Design System Synthesis

## Purpose
Analyze design assets and synthesize a semantic design system into a `DESIGN.md` file.

## When to Use
- Starting a new feature that needs design consistency
- Auditing an existing design system
- Creating a single source of truth for design tokens

## Workflow

### Step 1: Gather Assets
Collect existing design references:
- Screenshots or mockups
- Existing CSS/tokens files
- Brand guidelines
- Component library docs

### Step 2: Extract Tokens
Identify:
- **Colors**: primary, secondary, surface, text, accents
- **Typography**: font families, sizes, weights, line heights
- **Spacing**: grid system, padding scale, margins
- **Components**: buttons, cards, inputs, modals, badges
- **Effects**: shadows, borders, radius, transitions

### Step 3: Write DESIGN.md
Structure:
```markdown
# Design System — [Project Name]

## Colors
| Token | Value | Usage |
|-------|-------|-------|
| --color-primary | #... | CTAs, links |

## Typography
| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| --font-heading | 2rem | 700 | Page titles |

## Spacing
| Token | Value |
|-------|-------|
| --space-sm | 0.5rem |

## Components
### Button
- Height: [token]
- Padding: [token]
- Border radius: [token]
- States: default, hover, active, disabled
```

## Output
`DESIGN.md` in the project root or `.agents/output-styles/`.
