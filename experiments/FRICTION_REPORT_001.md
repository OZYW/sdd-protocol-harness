# Friction Report 001: Dry Run Observations

## Metadata

- Report ID: FR-001
- Source Experiment: EXP-001 (First End-to-End Dry Run)
- Date: 2026-06-09
- Protocol Version: SDD-001 v0.3

---

## Friction 1: Spec Review Infinite Loop

**Severity**: High
**Frequency**: Every loop with E2 Review
**Impact**: 11 minutes, ~46k tokens wasted on a simple function

### Observed Behavior

Spec Review Agent cycled 4 times before passing:

| Round | Blocking | Major | Minor | Verdict |
|-------|----------|-------|-------|---------|
| #1 | 2 | 2 | 4 | needs_revision |
| #2 | 0 | 4 | 6 | needs_revision |
| #3 | 1 | 4 | 6 | needs_revision |
| #4 | 0 | 0 | 0 | pass |

### Root Cause

`spec_review_agent.md` has **no exit criteria**. The 10-item checklist is exhaustive but unbounded. For a simple function, the reviewer found issues like:
- "Should Unicode grapheme clusters be specially handled?"
- "Is the data model complete?"
- "Are risks realistic?"

These are legitimate checklist items but lack **proportionality** — a single-function spec does not need the same review depth as a system architecture.

### Proposed Fix

Add exit criteria to `spec_review_agent.md`:

```markdown
## Exit Criteria

Review MUST terminate with `pass` if ANY of:
1. Zero blocking AND major issues ≤ 2 (after round 1)
2. Zero blocking AND major issues ≤ 1 (after round 2)
3. Max 3 rounds reached — human gate escalation

Review MUST terminate with `needs_revision` ONLY if:
- Blocking issues ≥ 1, OR
- Major issues ≥ 3 (after 2 rounds)
```

Add complexity-based review depth to `idea_brief.yaml`:
```yaml
complexity_estimate: simple | medium | complex
review_depth: minimal | standard | thorough
```

Simple features get `minimal` review (3 core checks only).

### Status
Proposed. Awaiting spec diff approval.

---

## Friction 2: Intake Agent Over-Questions Simple Ideas

**Severity**: Medium
**Frequency**: Every E1 Capture
**Impact**: Adds 4 assumption questions for trivial ideas

### Observed Behavior

For "build a function that reverses a string", Intake Agent generated 4 questions:
1. Should it handle Unicode/emoji specially?
2. Should it validate input types?
3. Should there be performance constraints?
4. Should it be a module, script, or include tests?

All marked as `blocking: false`, `routed_to: assumption`.

### Root Cause

`intake_agent.md` has **no question budget**. The agent asks as many questions as it can think of, regardless of idea complexity.

### Proposed Fix

Add question budget to `intake_agent.md`:

```markdown
## Question Budget

- Simple feature (single function, single file): Max 2 questions
- Medium feature (module, UI component, API endpoint): Max 4 questions
- Complex feature (system, architecture, multi-service): Max 6 questions

If idea is clearly simple, mark non-critical questions as backlog instead of assumption.
```

### Status
Proposed. Awaiting spec diff approval.

---

## Friction 3: Review Results Not Persisted

**Severity**: Medium
**Frequency**: Every E2 Review
**Impact**: No audit trail of what was reviewed or why it failed

### Observed Behavior

Phase history references `review_result.yaml`, `review_result_2.yaml`, etc., but these files were never created. Review results only existed in Agent tool output context.

### Root Cause

`spec_review_agent.md` says "Output: Review report" but does not specify a file path or schema.

### Proposed Fix

Update `spec_review_agent.md` output section:

```markdown
## Output

Save review result to `.sdd/artifacts/loops/{LOOP_ID}/review_result_{round}.yaml`:

```yaml
review_result:
  review_id: "R-001"
  loop_id: "L001"
  round: 1
  status: pass | needs_revision
  blocking_issues: []
  major_issues: []
  minor_issues: []
  verdict: "..."
```
```

Add `review_result.yaml` to artifact templates.

### Status
Proposed. Awaiting spec diff approval.

---

## Friction 4: Implementation Agent Loses Task Granularity

**Severity**: Low
**Frequency**: Every E5 Implementation
**Impact**: Task-level tracking is theoretical, not actual

### Observed Behavior

Task Plan defined 15 tasks with dependencies. Implementation Agent was called once and executed all tasks. While the result was correct, there was no per-task Agent call or per-task status update.

### Root Cause

Protocol allows either "one Agent per task" or "one Agent for all tasks". The Host chose the latter for efficiency. This is valid per protocol but loses the value of task-level orchestration.

### Proposed Fix

No protocol change needed. Add guidance to `SDD_PROTOCOL.md`:

```markdown
## Implementation Strategy

Host may choose implementation granularity based on complexity:
- Simple feature (≤ 5 tasks): Single Agent call acceptable
- Medium feature (6-15 tasks): Batch by dependency layer
- Complex feature (> 15 tasks): One Agent call per task group

The key constraint: Every task must have `status: completed` and evidence before E6.
```

### Status
Accepted as design choice. No spec change needed.

---

## Friction 5: Human Gate Formatting Noise

**Severity**: Low
**Frequency**: Every E3 Human Gate
**Impact**: Minor visual clutter

### Observed Behavior

Gate presentation included `✻ Baked for 18m 20s` and Claude Code skill/system messages in the output. The core content was correct but surrounded by framework noise.

### Root Cause

Claude Code's skill execution prints timing and token usage. This is a presentation-layer issue, not a protocol issue.

### Proposed Fix

None. This is Claude Code UI behavior, not protocol behavior. Human Gate format itself was correct (conversational, no file review).

### Status
Won't fix. External to protocol scope.

---

## Summary

| Friction | Severity | Fix Type | Effort | Status |
|----------|----------|----------|--------|--------|
| Review infinite loop | High | spec_review_agent.md + phases.md | Medium | Proposed |
| Intake over-questions | Medium | intake_agent.md | Low | Proposed |
| Review results not persisted | Medium | spec_review_agent.md + new template | Medium | Proposed |
| Implementation task granularity | Low | SDD_PROTOCOL.md guidance | Low | Accepted |
| Gate formatting noise | Low | None | None | Won't fix |

## Recommended Priority

1. **Fix review exit criteria** — Blocks efficient use on simple features
2. **Fix review result persistence** — Required for audit trail completeness
3. **Fix intake question budget** — Reduces user friction
4. **Re-run Dry Run** with fixes to validate
