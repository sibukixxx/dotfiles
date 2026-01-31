---
name: business-to-requirements
description: Transform business ideas, problems, and conversations into structured technical requirements. Use this skill when users want to (1) create a PRD from a vague idea or feature request, (2) derive technical requirements from a business problem, (3) formalize requirements through iterative conversation, or (4) create user stories and acceptance criteria from business needs. Triggers on requests like "help me write requirements", "create a PRD for...", "what should the spec include", or discussions about new features/products.
---

# Business to Requirements

Transform vague business ideas into actionable technical specifications through structured elicitation and documentation.

## Workflow Decision Tree

**Determine the starting point:**

1. **Idea → PRD**: User has a feature/product idea
   - Elicit requirements through questions
   - Output: Complete PRD document

2. **Problem → Solution Requirements**: User describes a business problem
   - Understand the problem deeply first
   - Derive solution requirements
   - Output: Requirements with rationale

3. **Conversation → Spec**: User wants to discuss and refine
   - Iterative Q&A to clarify
   - Build spec incrementally
   - Output: Formalized specification

## Core Process

### Step 1: Understand Context

Ask targeted questions to understand:
- **Problem**: What problem are we solving? Who has this problem?
- **Users**: Who are the primary/secondary users?
- **Success**: How will we measure success?
- **Constraints**: Timeline, budget, technical limitations?

See [requirements_elicitation.md](references/requirements_elicitation.md) for comprehensive question templates.

### Step 2: Clarify Ambiguity

Surface and resolve:
- Vague requirements → Specific, measurable criteria
- Implicit assumptions → Explicit decisions
- Conflicting needs → Prioritized trade-offs
- Edge cases → Defined behaviors

### Step 3: Structure Requirements

Organize into:
- **User Stories**: As a [user], I want [goal], so that [benefit]
- **Functional Requirements**: What the system must do (P0/P1/P2)
- **Non-Functional Requirements**: Performance, security, scalability
- **Acceptance Criteria**: Given/When/Then or checklist format

See [user_stories.md](references/user_stories.md) for format and examples.

### Step 4: Document

Output in requested format:
- **PRD**: Full product requirements document
- **User Stories**: Story-focused format
- **Technical Spec**: Implementation-focused

See [prd_guide.md](references/prd_guide.md) for PRD structure and examples.

## Quick Reference

### User Story Format
```
As a [persona],
I want [goal],
So that [benefit].

Acceptance Criteria:
- Given [context], when [action], then [outcome]
```

### Priority Levels
| Level | Meaning | Guideline |
|-------|---------|-----------|
| P0 | Must Have | Launch blocked without this |
| P1 | Should Have | Important, target v1.1 |
| P2 | Nice to Have | Backlog for future |

### Requirement Quality Checklist
- [ ] Specific (not vague)
- [ ] Measurable (has success criteria)
- [ ] Achievable (technically feasible)
- [ ] Relevant (ties to business goal)
- [ ] Testable (has acceptance criteria)

## Example Interaction

**User**: I want to add notifications to our app

**Response approach**:
1. Clarify: What triggers notifications? Push/email/in-app?
2. Users: Who receives them? Can users configure preferences?
3. Content: What information in each notification?
4. Timing: Real-time or batched? Quiet hours?
5. Edge cases: What if user has notifications disabled?

Then structure findings into user stories with acceptance criteria.

## References

- [PRD Guide](references/prd_guide.md) - PRD structure, writing guidelines, examples
- [User Stories Guide](references/user_stories.md) - Format, INVEST criteria, domain examples
- [Requirements Elicitation](references/requirements_elicitation.md) - Discovery questions, clarification patterns, edge cases
