# Skill Scaffold Template — Processing Layer

> Use this scaffold when creating any new skill in a project using the layer separation pattern.
> Replace all `(例)` and `<placeholder>` sections with your actual logic.

---

```yaml
---
name: <skill-name>
description: |
  <1-2 sentences: what this skill does and when to trigger it>
  Trigger on: <Japanese and English phrases that should activate this skill>
---
```

# <Skill Name>

## What This Skill Does

```
Input:  <file path or data source>
Output: <file path or format>
Reads from CLAUDE.md: <list of sections this skill depends on>
```

---

## Context Loading

**Before executing any processing**, read `CLAUDE.md` and extract:

```
required:
  - stakeholders          # Who receives this output → affects filtering and tone
  - internal_boundary     # What must be removed from output
  - reporting_style       # Granularity and tone for target audience

optional:
  - terminology           # Terms to preserve/translate accurately
  - regulatory_constraints # Content that must never appear
```

If `CLAUDE.md` is missing or incomplete, STOP and report:
> "CLAUDE.md の [セクション名] が未記入です。処理を続行できません。"

---

## Processing Steps

### Step 1: Load Input
```
- Read from: <input path>
- Format: <markdown / json / csv / etc.>
- Expected structure: <describe what the input looks like>
```

### Step 2: Apply Domain Filters
Using the context loaded from CLAUDE.md:

```
- Filter out any content matching `internal_boundary`
- Apply `terminology` glossary (replace internal terms with external equivalents if needed)
- Check against `regulatory_constraints` — flag any violations before proceeding
```

### Step 3: Transform Content
```
- Restructure for target audience based on `reporting_style.<audience>`
- Adjust granularity: <what to keep, what to summarize, what to drop>
- Rewrite tone if needed
```

### Step 4: Write Output
```
- Write to: <output path>
- Format: <markdown / docx / etc.>
- Include metadata: date, source file, skill version
```

---

## Portability Check

This skill is portable if CLAUDE.md alone controls:
- [ ] What information gets filtered
- [ ] Who the audience is
- [ ] What tone/granularity to use
- [ ] What terms need translation

If any of these are hardcoded in this skill file → move them to CLAUDE.md.

---

## Example: Applying to a New Project

To reuse this skill in a different project:
1. Copy this skill file (no changes needed)
2. Write a new `CLAUDE.md` for the target project
3. Run the skill — output will reflect the new project's domain context automatically

---

## Error Handling

| Condition | Action |
|---|---|
| Input file not found | Report path, stop |
| CLAUDE.md missing required section | List missing sections, stop |
| Regulatory violation detected in content | Flag lines, ask for confirmation before outputting |
| Output directory doesn't exist | Create it, proceed |
