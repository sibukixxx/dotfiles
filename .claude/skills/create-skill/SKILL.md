---
name: create-skill
description: Create new Claude skills following Anthropic's official guidelines. Use when user asks to create a skill, build a skill, make a new skill, or wants to extend Claude's capabilities with custom workflows. Generates properly structured SKILL.md with frontmatter, references, and scripts.
---

# Skill Creator

Create skills following Anthropic's official guidelines and best practices.

## References

- **Anthropic Guide**: See [references/anthropic-skill-guide.md](references/anthropic-skill-guide.md) for complete patterns and troubleshooting
- **Specification**: See [references/specification.md](references/specification.md) for technical requirements

## Skill Creation Process

### Step 1: Understand the Skill

Ask these questions to clarify:
1. What specific tasks should the skill handle?
2. What would users say to trigger this skill?
3. What outputs should it produce?
4. Does it need scripts, references, or assets?

### Step 2: Plan the Structure

```
skill-name/
├── SKILL.md              # Required
├── scripts/              # Executable code if needed
├── references/           # Documentation for Claude to read
└── assets/              # Templates, images for output
```

Decide what reusable resources to include:
- **scripts/**: Code that gets rewritten repeatedly or needs deterministic reliability
- **references/**: Domain knowledge, schemas, API docs
- **assets/**: Templates, brand assets, boilerplate

### Step 3: Create the Skill

#### Directory and Files

```bash
mkdir -p ~/.claude/skills/{skill-name}/references
```

#### SKILL.md Template

```yaml
---
name: skill-name-in-kebab-case
description: [What it does]. Use when [trigger phrases and contexts].
---

# Skill Name

## Overview

Brief description of the skill's purpose.

## Instructions

### Step 1: [First Major Step]

Clear explanation.

Example:
\`\`\`bash
command example
\`\`\`

### Step 2: [Next Step]

Continue with clear, actionable instructions.

## Examples

### Example 1: [Common scenario]

User says: "[trigger phrase]"
Actions:
1. First action
2. Second action
Result: [expected output]

## Troubleshooting

### Error: [Common error]
Cause: [Why it happens]
Solution: [How to fix]
```

### Step 4: Validate

Check these requirements:

**Naming**:
- [ ] Folder is kebab-case
- [ ] SKILL.md is exact spelling
- [ ] name matches folder name

**Frontmatter**:
- [ ] Has `---` delimiters
- [ ] name: kebab-case, 1-64 chars
- [ ] description: includes WHAT and WHEN, under 1024 chars
- [ ] No XML tags (< >)

**Content**:
- [ ] Under 500 lines
- [ ] Instructions are specific and actionable
- [ ] Examples provided
- [ ] Error handling included
- [ ] References clearly linked

### Step 5: Test

1. **Triggering**: Does it load for relevant queries?
2. **Functionality**: Does it produce correct outputs?
3. **Edge cases**: Does error handling work?

## Critical Rules

1. **SKILL.md must be exact**: Case-sensitive filename
2. **kebab-case only**: No spaces, no capitals in folder/name
3. **No README.md**: All docs go in SKILL.md or references/
4. **No XML in frontmatter**: Security restriction
5. **No "claude"/"anthropic" in name**: Reserved
6. **Description must include triggers**: Both WHAT and WHEN

## Common Mistakes

### Bad Description
```yaml
# Too vague
description: Helps with projects.

# Missing triggers
description: Creates sophisticated documentation.
```

### Good Description
```yaml
description: Manages Linear project workflows including sprint planning, task creation, and status tracking. Use when user mentions "sprint", "Linear tasks", "project planning", or asks to "create tickets".
```

## Quick Workflow

1. `mkdir -p ~/.claude/skills/my-skill/references`
2. Create SKILL.md with frontmatter + instructions
3. Add references/ files for detailed docs
4. Add scripts/ for executable code
5. Test triggering and functionality
