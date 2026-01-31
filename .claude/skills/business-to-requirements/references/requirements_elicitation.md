# Requirements Elicitation Guide

## Table of Contents
1. [Discovery Questions](#discovery-questions)
2. [Clarification Patterns](#clarification-patterns)
3. [Edge Case Identification](#edge-case-identification)
4. [Prioritization Framework](#prioritization-framework)

## Discovery Questions

### Problem Understanding
- What problem are you trying to solve?
- Who experiences this problem?
- How are users currently handling this?
- What happens if we don't solve this?
- What's the cost of the current approach?

### User Understanding
- Who are the primary users?
- Who are secondary/admin users?
- What's their technical proficiency?
- What devices/platforms do they use?
- What are their time/context constraints?

### Success Criteria
- How will you know this is successful?
- What metrics matter most?
- What's the minimum viable improvement?
- What's the ideal outcome?

### Constraints
- What's the timeline?
- Are there budget constraints?
- What technical limitations exist?
- Are there regulatory/compliance requirements?
- What integrations are required?

### Scope
- What is explicitly in scope?
- What is explicitly out of scope?
- What are the dependencies?
- What could block this project?

## Clarification Patterns

### Ambiguous Requirements

When requirement is vague:
```
Original: "The system should be user-friendly"

Clarify:
- What specific tasks should be easy?
- Who defines "user-friendly"?
- Are there reference products/UIs to emulate?
- What's the acceptable learning curve?
```

### Implicit Assumptions

Surface hidden assumptions:
```
Original: "Users can upload files"

Clarify:
- What file types?
- What size limits?
- Single or multiple files?
- What happens after upload?
- Who can see uploaded files?
```

### Conflicting Requirements

When requirements conflict:
```
Original: "Fast AND comprehensive"

Clarify:
- Which is higher priority?
- Can we have tiers (quick vs deep)?
- What's the performance threshold?
- What's the completeness threshold?
```

## Edge Case Identification

### Question Templates

**Volume/Scale**
- What if there are 0 items?
- What if there are millions of items?
- What's the expected typical volume?

**Timing**
- What if action is repeated rapidly?
- What if action takes too long?
- What about timezone differences?

**Permissions**
- What if user lacks permission?
- What if permission changes mid-action?
- What about shared resources?

**Data**
- What if data is missing?
- What if data is malformed?
- What about special characters/emoji?

**Network/System**
- What if connection drops?
- What if dependent service is down?
- What about concurrent modifications?

### Common Edge Cases by Feature Type

**Search**
- Empty results
- Too many results
- Special characters in query
- Very long query

**Forms**
- Required field empty
- Input too long
- Invalid format
- Duplicate submission

**Lists/Tables**
- Empty state
- Single item
- Pagination boundaries
- Sort edge cases

**File Operations**
- Empty file
- Corrupted file
- Unsupported format
- File in use

## Prioritization Framework

### MoSCoW Method

| Priority | Meaning | Guideline |
|----------|---------|-----------|
| **Must** | Critical | Launch blocked without this |
| **Should** | Important | Significant value, not blocking |
| **Could** | Desired | Nice to have if time permits |
| **Won't** | Not now | Explicitly deferred |

### Value vs Effort Matrix

```
High Value / Low Effort  → Do First (Quick Wins)
High Value / High Effort → Plan Carefully
Low Value / Low Effort   → Fill-in Work
Low Value / High Effort  → Avoid
```

### Questions for Prioritization
- What's the impact on users if this is missing?
- What's the revenue/cost impact?
- Does this enable other features?
- Is there a workaround?
- What's the risk of delaying?
