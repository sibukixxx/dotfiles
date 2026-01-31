# PRD (Product Requirements Document) Guide

## Table of Contents
1. [PRD Structure](#prd-structure)
2. [Writing Guidelines](#writing-guidelines)
3. [Examples](#examples)

## PRD Structure

### Required Sections

```markdown
# [Product/Feature Name] PRD

## 1. Overview
- **Problem Statement**: What problem are we solving?
- **Target Users**: Who is this for?
- **Success Metrics**: How do we measure success?

## 2. Background & Context
- Current state and pain points
- Why now? What triggered this initiative?
- Relevant data or research

## 3. Goals & Non-Goals
### Goals
- Specific, measurable objectives

### Non-Goals
- Explicitly out of scope items

## 4. User Stories
Format: As a [user type], I want [action] so that [benefit]

## 5. Functional Requirements
### P0 (Must Have)
- Critical features for launch

### P1 (Should Have)
- Important but not blocking

### P2 (Nice to Have)
- Future enhancements

## 6. Non-Functional Requirements
- Performance
- Security
- Scalability
- Accessibility

## 7. Technical Considerations
- Architecture impacts
- Dependencies
- Integration points

## 8. Milestones & Timeline
- Phase breakdown
- Key deliverables

## 9. Open Questions
- Unresolved items requiring decisions

## 10. Appendix
- Mockups, references, research
```

## Writing Guidelines

### Be Specific
- Bad: "The system should be fast"
- Good: "Page load time under 2 seconds for 95th percentile"

### Focus on What, Not How
- PRD defines WHAT to build
- Technical spec defines HOW to build it

### Use Measurable Criteria
- Include acceptance criteria for each requirement
- Define "done" clearly

### Prioritize Ruthlessly
- P0: Launch blocker
- P1: Important, plan for v1.1
- P2: Backlog

## Examples

### Good Problem Statement
```
Users currently spend an average of 15 minutes manually entering
shipping information for each international order. This leads to
errors in 23% of shipments and customer complaints about delivery
delays.
```

### Good User Story
```
As a warehouse manager, I want to scan barcodes to auto-populate
shipping forms so that I can process orders 5x faster with fewer errors.
```

### Good Success Metric
```
- Reduce order processing time from 15 min to 3 min
- Decrease shipping errors from 23% to under 5%
- Achieve 90% user adoption within 30 days of launch
```
