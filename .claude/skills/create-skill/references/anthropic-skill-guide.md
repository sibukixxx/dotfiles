# The Complete Guide to Building Skills for Claude

Source: https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf

## Core Design Principles

### Progressive Disclosure

Skills use a three-level system:
1. **YAML frontmatter**: Always loaded. Just enough for Claude to know when to use the skill.
2. **SKILL.md body**: Loaded when skill triggers. Full instructions and guidance.
3. **Linked files**: Additional files Claude discovers only as needed.

### Composability

Claude can load multiple skills simultaneously. Skills should work well alongside others.

### Portability

Skills work identically across Claude.ai, Claude Code, and API.

## Skill Structure

```
skill-name/
├── SKILL.md              # Required - main skill file
├── scripts/              # Optional - executable code
├── references/           # Optional - documentation
└── assets/              # Optional - templates, etc.
```

### Critical Rules

- SKILL.md must be exactly `SKILL.md` (case-sensitive)
- Folder naming: kebab-case only (`notion-project-setup`, not `Notion Project Setup`)
- No README.md inside skill folder
- No XML angle brackets (< >) in frontmatter
- No "claude" or "anthropic" in skill name (reserved)

## YAML Frontmatter

### Required Fields

```yaml
---
name: skill-name-in-kebab-case
description: What it does and when to use it. Include specific trigger phrases.
---
```

### Field Requirements

**name** (required):
- kebab-case only
- No spaces or capitals
- Should match folder name
- 1-64 characters

**description** (required):
- MUST include BOTH: What the skill does AND When to use it
- Under 1024 characters
- Include specific tasks users might say
- Mention file types if relevant

**license** (optional): Use if making skill open source

**compatibility** (optional): 1-500 characters, environment requirements

**metadata** (optional): Any custom key-value pairs (author, version, mcp-server)

### Good Description Examples

```yaml
# Good - specific and actionable
description: Analyzes Figma design files and generates developer handoff documentation. Use when user uploads .fig files, asks for "design specs", "component documentation", or "design-to-code handoff".

# Good - includes trigger phrases
description: Manages Linear project workflows including sprint planning, task creation, and status tracking. Use when user mentions "sprint", "Linear tasks", "project planning", or asks to "create tickets".
```

### Bad Description Examples

```yaml
# Too vague
description: Helps with projects.

# Missing triggers
description: Creates sophisticated multi-page documentation systems.

# Too technical, no user triggers
description: Implements the Project entity model with hierarchical relationships.
```

## Skill Use Case Categories

### Category 1: Document & Asset Creation

Creating consistent, high-quality output (documents, presentations, apps, designs, code)

Key techniques:
- Embedded style guides and brand standards
- Template structures for consistent output
- Quality checklists before finalizing
- No external tools required

### Category 2: Workflow Automation

Multi-step processes with consistent methodology

Key techniques:
- Step-by-step workflow with validation gates
- Templates for common structures
- Built-in review and improvement suggestions
- Iterative refinement loops

### Category 3: MCP Enhancement

Workflow guidance to enhance MCP server tool access

Key techniques:
- Coordinates multiple MCP calls in sequence
- Embeds domain expertise
- Provides context users would otherwise need
- Error handling for common MCP issues

## Workflow Patterns

### Pattern 1: Sequential Workflow Orchestration

Use when users need multi-step processes in a specific order.

Key techniques:
- Explicit step ordering
- Dependencies between steps
- Validation at each stage
- Rollback instructions for failures

### Pattern 2: Multi-MCP Coordination

Use when workflows span multiple services.

Key techniques:
- Clear phase separation
- Data passing between MCPs
- Validation before moving to next phase
- Centralized error handling

### Pattern 3: Iterative Refinement

Use when output quality improves with iteration.

Key techniques:
- Explicit quality criteria
- Iterative improvement
- Validation scripts
- Know when to stop iterating

### Pattern 4: Context-aware Tool Selection

Use when same outcome needs different tools depending on context.

Key techniques:
- Clear decision criteria
- Fallback options
- Transparency about choices

### Pattern 5: Domain-specific Intelligence

Use when skill adds specialized knowledge beyond tool access.

Key techniques:
- Domain expertise embedded in logic
- Compliance before action
- Comprehensive documentation
- Clear governance

## Best Practices for Instructions

### Be Specific and Actionable

```markdown
# Good
Run `python scripts/validate.py --input {filename}` to check data format.
If validation fails, common issues include:
- Missing required fields (add them to the CSV)
- Invalid date formats (use YYYY-MM-DD)

# Bad
Validate the data before proceeding.
```

### Include Error Handling

```markdown
## Common Issues

### MCP Connection Failed
If you see "Connection refused":
1. Verify MCP server is running
2. Confirm API key is valid
3. Try reconnecting
```

### Reference Bundled Resources Clearly

```markdown
Before writing queries, consult `references/api-patterns.md` for:
- Rate limiting guidance
- Pagination patterns
- Error codes and handling
```

## Testing Approach

### 1. Triggering Tests

- Should trigger on obvious tasks
- Should trigger on paraphrased requests
- Should NOT trigger on unrelated topics

### 2. Functional Tests

- Valid outputs generated
- API calls succeed
- Error handling works
- Edge cases covered

### 3. Performance Comparison

Compare with and without skill:
- Message count
- API call failures
- Tokens consumed

## Troubleshooting

### Skill Won't Upload

**Error: "Could not find SKILL.md"**
- Rename to exactly SKILL.md (case-sensitive)

**Error: "Invalid frontmatter"**
- Ensure `---` delimiters exist
- Check for unclosed quotes

**Error: "Invalid skill name"**
- Use kebab-case (my-cool-skill, not My Cool Skill)

### Skill Doesn't Trigger

- Description too generic
- Missing trigger phrases
- Missing relevant file types

### Skill Triggers Too Often

1. Add negative triggers
2. Be more specific
3. Clarify scope

### Instructions Not Followed

1. Keep instructions concise
2. Put critical instructions at the top
3. Avoid ambiguous language
4. For critical validations, use scripts instead of language instructions

### Large Context Issues

- Move detailed docs to references/
- Keep SKILL.md under 5,000 words
- Reduce enabled skills if > 20-50 simultaneously

## Quick Checklist

### Before You Start
- [ ] Identified 2-3 concrete use cases
- [ ] Tools identified (built-in or MCP)
- [ ] Planned folder structure

### During Development
- [ ] Folder named in kebab-case
- [ ] SKILL.md file exists (exact spelling)
- [ ] YAML frontmatter has `---` delimiters
- [ ] name field: kebab-case, no spaces
- [ ] description includes WHAT and WHEN
- [ ] No XML tags (< >) anywhere
- [ ] Instructions are clear and actionable
- [ ] Error handling included
- [ ] Examples provided
- [ ] References clearly linked

### Before Upload
- [ ] Tested triggering on obvious tasks
- [ ] Tested triggering on paraphrased requests
- [ ] Verified doesn't trigger on unrelated topics
- [ ] Functional tests pass
