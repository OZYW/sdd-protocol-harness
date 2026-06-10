# Experiment Log 001: First End-to-End Dry Run

## Metadata

- Experiment ID: EXP-001
- Date: 2026-06-09
- Duration: ~20 minutes (14:17 to 14:37 UTC)
- Location: New Claude Code session, `~/sdd-test-project`
- Skill: `sdd-protocol` installed at `~/.claude/skills/sdd-protocol/`
- Protocol Version: SDD-001 v0.3

## Hypothesis

A filesystem-based SDD Protocol harness can enforce structured artifacts, human gates, independent agent reviews, and evidence collection in a real Claude Code session.

## Method

1. Install harness files (`.sdd/`, `.claude/SDD_PROTOCOL.md`) in a clean test directory
2. Install skill (`~/.claude/skills/sdd-protocol/`)
3. Start new Claude Code session in test directory
4. Trigger: `/sdd-protocol build a Python function that takes a string and returns its reverse`
5. Observe full loop execution from E1 to completion
6. Record all artifacts, state transitions, and friction points

## Results

### Phase Execution Trace

| Time | Phase | Agent | Decision | Outcome |
|------|-------|-------|----------|---------|
| 14:17 | E1 Capture | Intake Agent | continue | `idea_brief.yaml` produced |
| 14:17 | E2 Generate | Spec Agent | continue | `sdd_spec.yaml` produced |
| 14:19 | E2R Review #1 | Spec Review Agent | blocked | 2 blocking issues found |
| 14:20 | E2 Generate (revise) | Spec Agent | continue | Spec revised |
| 14:22 | E2R Review #2 | Spec Review Agent | blocked | 0 blocking, 4 major issues |
| 14:23 | E2 Generate (revise) | Spec Agent | continue | Spec revised round 2 |
| 14:25 | E2R Review #3 | Spec Review Agent | blocked | 1 blocking, 4 major issues |
| 14:26 | E2 Generate (revise) | Spec Agent | continue | Spec revised round 3 |
| 14:28 | E2R Review #4 | Spec Review Agent | pass | 0 issues |
| 14:28 | E3 Human Gate | Host | human_gate | Gate presented, user approved |
| 14:30 | E4 Compile | Task Compiler Agent | continue | `task_plan.yaml` produced (15 tasks) |
| 14:32 | E5 Implement | Implementation Agent | continue | Code + tests written |
| 14:35 | E6 Verify | Verification Agent | continue | 7/7 criteria verified, 0 defects |
| 14:36 | E7 Feedback | Host | human_gate | Evidence presented, user accepted |
| 14:37 | Completed | — | — | `status: completed` |

### Generated Artifacts

**Protocol Artifacts (YAML)**:
- `idea_brief.yaml` — Captured raw intent: "build a Python function that takes a string and returns its reverse"
- `sdd_spec.yaml` — Full spec with 6 functional behaviors, 7 acceptance criteria, risks, open questions
- `human_gate.yaml` — Gate record showing user approved with no modifications
- `task_plan.yaml` — 15 tasks mapped to spec clauses, dependency graph included
- `evidence_pack.yaml` — 2 evidence entries (test output + file review), all 7 criteria pass

**Implementation Artifacts**:
- `reverse.py` — 21-line Python function with docstring, type validation, Unicode-aware reversal
- `test_reverse.py` — 9 unit tests covering all acceptance criteria, all passing

### Evidence Summary

| Criterion | Method | Result |
|-----------|--------|--------|
| A-001 — ASCII reversal | `test` | Pass |
| A-002 — Mixed characters | `test` | Pass |
| A-003 — Unicode code points | `test` | Pass |
| A-004 — TypeError for bad input | `test` | Pass |
| A-005 — Empty string | `test` | Pass |
| A-006 — Single character | `test` | Pass |
| A-007 — Grapheme docs | `file` | Pass |

**Tests**: 9/9 passed, 0 failures, 0 errors

### Protocol Rules Validated

| Rule | Status | Evidence |
|------|--------|----------|
| Rule 1 — State inspection before action | Pass | Host reads `current_loop.yaml` before every transition |
| Rule 2 — No code without accepted spec | Pass | No code written before E3 approval |
| Rule 3 — Human Gate mandatory | Pass | Execution stopped at E3, conversational format used |
| Rule 4 — Evidence before completion | Pass | `evidence_pack.yaml` produced before claiming done |
| Rule 5 — Spec diff before product change | N/A | No spec changes requested in this loop |
| Rule 6 — Append-only trace | Pass | `phase_history.yaml` has 13 entries, no edits |
| Rule 7 — Determinism | Pass | Same state always yielded same phase decision |
| Rule 8 — Single active loop | N/A | No concurrent loops tested |
| Rule 9 — Review Agent independence | Pass | 4 independent Agent calls for review |
| Rule 10 — No direct spec modification | Pass | No post-gate spec modifications occurred |

### Friction Points Observed

See [FRICTION_REPORT_001.md](FRICTION_REPORT_001.md) for full analysis.

**High-friction**:
1. Spec Review cycled 4 times (11 min, ~46k tokens) for a simple function
2. No review exit condition — reviewer can always find more issues

**Medium-friction**:
3. Intake Agent generated 4 assumption questions for a trivial idea
4. Review results not saved as artifacts (only in Agent context)

**Low-friction**:
5. Implementation Agent executed all 15 tasks in one call (lost granularity)
6. Human Gate presentation had minor formatting issues (skill name printed)

## Conclusion

**HYPOTHESIS CONFIRMED.**

The SDD Protocol harness successfully enforced:
- Structured artifact generation (5 YAML files)
- Human gate at spec approval (conversational, no file review)
- Independent agent review (4 separate Agent calls)
- Evidence collection before completion (test output + file review)
- State-driven phase transitions (deterministic, file-based)

Loop completed from trigger to user acceptance with full traceability.

**Qualification**: Review friction is higher than acceptable for simple features. Exit criteria needed.

## Next Steps

1. Fix review exit conditions (max rounds, severity thresholds)
2. Fix intake question budget (scale with complexity)
3. Fix review result artifact persistence
4. Run second Dry Run with fixes applied
