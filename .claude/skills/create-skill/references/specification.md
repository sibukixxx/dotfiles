# Agent Skills Specification

Source: https://agentskills.io/specification

## Directory Structure

A skill is a directory containing at minimum a `SKILL.md` file:

```
skill-name/
└── SKILL.md          # Required
```

Optional directories: `scripts/`, `references/`, `assets/`

## SKILL.md Format

### Required Frontmatter

```yaml
---
name: skill-name
description: A description of what this skill does and when to use it.
---
```

### Optional Frontmatter Fields

```yaml
---
name: pdf-processing
description: Extract text and tables from PDF files, fill forms, merge documents.
license: Apache-2.0
compatibility: Requires git, docker, jq, and access to the internet
metadata:
  author: example-org
  version: "1.0"
allowed-tools: Bash(git:*) Bash(jq:*) Read
---
```

## Field Constraints

| Field | Required | Constraints |
|-------|----------|-------------|
| `name` | Yes | Max 64 chars. Lowercase letters, numbers, hyphens. No start/end hyphen. No consecutive hyphens. |
| `description` | Yes | Max 1024 chars. Non-empty. Describes what and when. |
| `license` | No | License name or reference to bundled file. |
| `compatibility` | No | Max 500 chars. Environment requirements. |
| `metadata` | No | Arbitrary key-value mapping. |
| `allowed-tools` | No | Space-delimited list of pre-approved tools. |

## Name Field Rules

Valid:
- `pdf-processing`
- `data-analysis`
- `code-review`

Invalid:
- `PDF-Processing` (uppercase)
- `-pdf` (starts with hyphen)
- `pdf--processing` (consecutive hyphens)

## Description Field Guidelines

Must describe:
1. What the skill does
2. When to use it
3. Specific keywords for task identification

Good:
```yaml
description: Extracts text and tables from PDF files, fills PDF forms, and merges multiple PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction.
```

Poor:
```yaml
description: Helps with PDFs.
```

## Progressive Disclosure

1. **Metadata** (~100 tokens): name + description at startup
2. **Instructions** (<5000 tokens recommended): SKILL.md body when activated
3. **Resources** (as needed): scripts/, references/, assets/ files

Keep SKILL.md under 500 lines. Move detailed reference to separate files.

## File References

Use relative paths from skill root:

```markdown
See [the reference guide](references/REFERENCE.md) for details.

Run the extraction script:
scripts/extract.py
```

Keep file references one level deep. Avoid deeply nested chains.

## Optional Directories

### scripts/

Executable code (Python, Bash, JavaScript). Should be:
- Self-contained or document dependencies
- Include helpful error messages
- Handle edge cases gracefully

### references/

Additional documentation loaded as needed:
- `REFERENCE.md` - Technical reference
- `FORMS.md` - Form templates
- Domain-specific files

Keep focused. Smaller files = less context usage.

### assets/

Static resources:
- Templates
- Images
- Data files

## Validation

```bash
skills-ref validate ./my-skill
```

Checks frontmatter validity and naming conventions.
