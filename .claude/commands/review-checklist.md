# Pre-Landing Review Checklist

## Instructions

Review the `git diff` output for the issues listed below. Be specific — cite `file:line` and suggest fixes. Skip anything that's fine. Only flag real problems.

**Two-pass review:**
- **Pass 1 (CRITICAL):** Run first. Highest severity — these cause incidents.
- **Pass 2 (INFORMATIONAL):** Lower severity but still actioned.

All findings get action via Fix-First Review: obvious mechanical fixes are applied automatically,
genuinely ambiguous issues are batched into a single user question.

**Output format:**

```
Pre-Landing Review: N issues (X critical, Y informational)

**AUTO-FIXED:**
- [file:line] Problem → fix applied

**NEEDS INPUT:**
- [file:line] Problem description
  Recommended fix: suggested fix
```

If no issues found: `Pre-Landing Review: No issues found.`

Be terse. For each issue: one line describing the problem, one line with the fix. No preamble.

---

## Review Categories

### Pass 1 — CRITICAL

#### SQL & Data Safety
- String interpolation in SQL — use parameterized queries or ORM methods
- TOCTOU races: check-then-set patterns that should be atomic
- N+1 queries: missing eager loading for associations used in loops/views

#### Race Conditions & Concurrency
- Read-check-write without uniqueness constraint or conflict handling
- Status transitions without atomic `WHERE old_status = ?` guard
- `find_or_create` on columns without unique DB index — concurrent duplicates

#### Input Validation & Trust Boundary
- User input written to DB/filesystem without validation
- External API responses (including LLM output) accepted without type/shape checks
- `html_safe`, `raw()`, `dangerouslySetInnerHTML` on user-controlled data (XSS)
- `eval()`, `exec()`, shell command injection vectors

#### Enum & Value Completeness
- New enum/status/type introduced but not handled in all `switch`/`case`/`match` consumers
- Allowlists or filter arrays missing the new value
- Existing `case`/`if-elsif` chains where the new value falls through to wrong default

### Pass 2 — INFORMATIONAL

#### Conditional Side Effects
- Code paths that branch but forget a side effect on one branch
- Log messages claiming an action happened when it was conditionally skipped

#### Magic Numbers & String Coupling
- Bare numeric literals used in multiple files — should be named constants
- Error message strings used as query filters elsewhere

#### Dead Code & Consistency
- Variables assigned but never read
- Comments/docstrings that describe old behavior after code changed
- Version mismatch between PR title and VERSION/CHANGELOG files

#### Test Gaps
- New public APIs without corresponding tests
- Tests asserting type/status but not side effects
- Security enforcement (auth, rate limiting) without integration tests
- Missing edge case tests: nil, empty, boundary values, concurrent access

#### Crypto & Entropy
- Truncation instead of hashing — less entropy, easier collisions
- `Math.random()` / `rand()` for security-sensitive values — use crypto-safe alternatives
- Non-constant-time comparisons (`==`) on secrets or tokens

#### Type Safety at Boundaries
- Values crossing language/serialization boundaries where type could change
- Hash/digest inputs that don't normalize types before serialization

#### Performance
- O(n²) algorithms applied to potentially large datasets
- N+1 in views — `Array#find` in loop instead of indexed lookup
- Missing database indexes for new query patterns
- Inline styles in templates re-parsed every render

---

## Severity Classification

```
CRITICAL (highest):              INFORMATIONAL (lower):
├─ SQL & Data Safety             ├─ Conditional Side Effects
├─ Race Conditions               ├─ Magic Numbers & String Coupling
├─ Input Validation              ├─ Dead Code & Consistency
└─ Enum & Value Completeness     ├─ Test Gaps
                                 ├─ Crypto & Entropy
                                 ├─ Type Safety at Boundaries
                                 └─ Performance
```

---

## Fix-First Heuristic

Determines whether the agent auto-fixes or asks the user.

```
AUTO-FIX (agent fixes without asking):     ASK (needs human judgment):
├─ Dead code / unused variables            ├─ Security (auth, XSS, injection)
├─ N+1 queries (missing eager loading)     ├─ Race conditions
├─ Stale comments contradicting code       ├─ Design decisions
├─ Magic numbers → named constants         ├─ Large fixes (>20 lines)
├─ Missing input validation on LLM output  ├─ Enum completeness across files
├─ Version/path mismatches                 ├─ Removing functionality
├─ Variables assigned but never read       └─ Anything changing user-visible
└─ Inline styles, O(n*m) view lookups        behavior
```

**Rule of thumb:** If the fix is mechanical and a senior engineer would apply it
without discussion, it's AUTO-FIX. If reasonable engineers could disagree, it's ASK.

**Critical findings default toward ASK** (inherently riskier).
**Informational findings default toward AUTO-FIX** (more mechanical).

---

## Suppressions — DO NOT flag these

- "X is redundant with Y" when redundancy is harmless and aids readability
- "Add a comment explaining why this threshold was chosen" — thresholds change, comments rot
- "This assertion could be tighter" when assertion already covers the behavior
- Consistency-only changes with no functional impact
- "Regex doesn't handle edge case X" when input is constrained and X never occurs
- ANYTHING already addressed in the diff you're reviewing — read the FULL diff first
