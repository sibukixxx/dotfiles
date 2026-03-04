---
name: pm-layer-separation
description: |
  Apply the "processing layer (skills) vs domain knowledge layer (CLAUDE.md)" separation pattern to Claude Code PM projects.
  ALWAYS use this skill when the user mentions: CLAUDE.mdの設計・作成・見直し, skillの作成・横展開・汎用化, 新プロジェクトのセットアップ, 自動化ワークフローの設計, "処理とドメイン知識を分けたい", "別プロジェクトに使い回したい", "PM自動化", "project setup", "portable skill", "layer separation", or any request to scaffold a Claude Code project structure.
  Also use when the user shares an existing CLAUDE.md or skill file and asks for feedback, refactoring, or analysis — even if they don't explicitly mention layer separation.
---

# PM Layer Separation Pattern

## Core Concept

```
CLAUDE.md  = Domain Knowledge Layer  (WHO, WHAT, WHY — project-specific)
skills/    = Processing Layer         (HOW — reusable across projects)
```

**The key insight**: The same processing logic produces different outputs when injected with different domain knowledge. Skills are generic; CLAUDE.md is specific.

---

## Claude Code — Execution Context

This skill runs in Claude Code (terminal). Always operate on real files:

```bash
# Discover project structure before doing anything
find . -name "CLAUDE.md" -o -name "SKILL.md" | head -20
cat CLAUDE.md 2>/dev/null || echo "No CLAUDE.md found — new project"
ls skills/ 2>/dev/null || echo "No skills/ directory found"
```

When generating files, write them directly to the project directory. Do not just show content — create the actual files.

```bash
# New project
mkdir -p skills/<workflow-name>
# Write CLAUDE.md and skills/<workflow-name>/SKILL.md using the templates
```

---

## When to Use This Skill

- **New project setup**: Generate CLAUDE.md template + matching skill scaffolding
- **Existing project audit**: Detect layer mixing and propose separation
- **New skill design**: Ensure the skill reads domain context from CLAUDE.md rather than hardcoding it
- **Cross-project expansion**: Port an existing skill by only swapping CLAUDE.md

---

## Step 1: Diagnose the Situation

**In Claude Code, always read the filesystem first before asking questions.**

```bash
# Run these to orient yourself
find . -maxdepth 3 -name "CLAUDE.md" -o -name "SKILL.md" | sort
cat CLAUDE.md 2>/dev/null
ls -la skills/ 2>/dev/null
```

Determine from the files:
1. **New or existing project?** — No CLAUDE.md = new project
2. **What workflows are planned/in use?** — Read existing SKILL.md files
3. **Is there layer mixing?** — Look for processing instructions inside CLAUDE.md, or domain terms hardcoded in skill files

Only ask the user for information that cannot be inferred from files:
- What automated workflows do you want to build? (if no skills/ exist yet)
- Who are the stakeholders and what are the constraints? (if no CLAUDE.md exists)

---

## Step 2: Identify What Belongs Where

### CLAUDE.md (Domain Knowledge Layer)

Always goes here:
- **Stakeholders**: Who they are, their roles, what they care about
- **Internal vs External boundary**: What information stays internal, what can be shared
- **Industry/regulatory constraints**: Things that must never be written, legal restrictions
- **Terminology glossary**: Project-specific terms and their meanings
- **Reporting granularity norms**: How detailed reports should be for each audience
- **Project context**: Goals, current phase, key decisions made

Never put here:
- Step-by-step processing instructions ("Read file A, transform it, write to B")
- Tool invocation sequences
- Generic workflow logic

### skills/ (Processing Layer)

Always goes here:
- Input/output file paths and formats
- Transformation steps (what to read, how to process, where to output)
- Tool usage sequences
- Error handling logic

Never put here:
- Who the stakeholders are
- What specific information to filter (reference CLAUDE.md instead)
- Project-specific terminology definitions

---

## Step 3: Design the Skill Interface

A well-designed skill has a clear **context injection point** — where it reads domain knowledge from CLAUDE.md.

**Pattern: Explicit CLAUDE.md Reference**
```markdown
## Context Loading
Before executing, read CLAUDE.md and extract:
- `stakeholders`: Who will receive this output
- `internal_boundary`: What information must be filtered out
- `terminology`: Domain-specific terms to preserve accurately
- `reporting_style`: Tone and granularity for this audience
```

This makes the skill's dependency on domain knowledge explicit and testable.

---

## Step 4: Generate Artifacts — Write Actual Files

### For New Projects

Read the templates first, then write real files:
```
Read: references/claude-md-template.md   → customize → write to ./CLAUDE.md
Read: references/skill-scaffold-template.md → customize → write to ./skills/<name>/SKILL.md
```

Customization means filling in every placeholder based on what you know about the project. Do not output a generic template — fill in actual stakeholder names, actual boundary rules, actual terminology.

### For Existing Projects (Audit & Refactor)

1. Read the existing `CLAUDE.md` line by line
2. Classify each section as **Domain Knowledge** (→ stays in CLAUDE.md) or **Processing Logic** (→ extract to skill)
3. Output a classification table showing the proposed split (see `references/examples.md` for format)
4. Ask for confirmation, then write the refactored files in-place

```bash
# After confirmation
cp CLAUDE.md CLAUDE.md.backup   # always backup before overwriting
# Write refactored CLAUDE.md and new skill files
```

---

## Step 5: Validate Portability

After creating or refactoring, verify:

**Portability test**: Can this skill work in a different project by *only* changing CLAUDE.md?
- ✅ If yes: Layer separation is correct
- ❌ If no: The skill contains hardcoded domain knowledge — extract it

**Completeness test**: Does CLAUDE.md contain everything a new team member needs to make judgment calls?
- ✅ If yes: Domain knowledge is complete
- ❌ If no: Missing context will cause the skill to produce wrong outputs silently

---

## Reference Files

- `references/claude-md-template.md` — Full CLAUDE.md template with all sections
- `references/skill-scaffold-template.md` — Skill scaffold with context injection points
- `references/examples.md` — Before/after examples of layer separation

Read these when generating artifacts for the user.
