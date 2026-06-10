# SDD Protocol — Phase Definitions and Transitions

## Phase List

| ID | Name | Description | Entry Condition | Exit Condition |
|----|------|-------------|-----------------|----------------|
| E1 | Capture | Capture user idea as structured brief | User triggers `/sdd-start` | `idea_brief.yaml` produced |
| E2 | Generate Spec | Convert brief into SDD spec | E1 complete | `sdd_spec.yaml` produced |
| E2R | Review Spec | Independent review of spec | E2 complete | Review passes/fails |
| E3 | Human Gate | Request human confirmation of spec | E2R passed | Human approves/revises/rejects |
| E4 | Compile Tasks | Convert spec into task plan | E3 approved | `task_plan.yaml` produced |
| E5 | Implement | Execute tasks via Agent tools | E4 complete | All tasks claimed complete |
| E6 | Verify | Collect evidence before completion | E5 complete | Evidence pack accepted |
| E7 | Feedback | Await human acceptance or feedback | E6 complete | User accepts/gives feedback |
| E8 | Spec Diff | Produce diff when product definition changes | E7 feedback = spec_change | `spec_diff.yaml` produced |

## Deterministic Transition Rules

Given `current_loop.yaml`, the next phase is determined by these rules **in order**:

### Rule 1: Start New Loop
```
IF status == "idle" AND user says "/sdd-start <idea>":
  CREATE new loop with loop_id = next sequential ID
  SET status = "active"
  SET current_phase = "e1_capture"
  APPEND trace entry
```

### Rule 2: Auto-Advance (No Gate)
```
IF status == "active" AND current_phase == "e1_capture" AND idea_brief.yaml exists:
  SET current_phase = "e2_generate_spec"
  APPEND trace entry

IF status == "active" AND current_phase == "e2_generate_spec" AND sdd_spec.yaml exists:
  SET current_phase = "e2_review"
  APPEND trace entry

IF status == "active" AND current_phase == "e2_review" AND review_result.status == "pass":
  SET current_phase = "e3_human_gate"
  APPEND trace entry

IF status == "active" AND current_phase == "e2_review" AND review_result.status == "needs_revision":
  SET current_phase = "e2_generate_spec"
  APPEND trace entry (with issue list)

IF status == "active" AND current_phase == "e4_compile_tasks" AND task_plan.yaml exists:
  READ sdd_spec.yaml
  IF sdd_spec.environment_boundary.status == "accepted":
    SET current_phase = "e5_implement"
    APPEND trace entry
  ELSE:
    DECISION = blocked
    ACTION = STOP. Present Environment Boundary Gate.
    NOTE = "Task Plan exists but environment_boundary is not accepted. Human must select runtime carrier, language, package manager before implementation."
    DO NOT advance to E5
```

### Rule 2.5: E2_Review — Spec Review Agent (MANDATORY INDEPENDENCE)

**Critical Rule**: This Agent call MUST be independent from E2_GenerateSpec.

- **Independence requirements**:
  1. Must be a separate `Agent` tool call, not continuation of Spec Agent
  2. Sub-agent MUST NOT have access to Spec Agent's internal reasoning
  3. Sub-agent receives ONLY: `sdd_spec.yaml` file path + `references/spec_review_agent.md`
  4. Host MUST NOT summarize or paraphrase the spec before handing off
  5. Sub-agent reads spec directly from file, not from Host's context

- **Verification of independence**:
  Host must confirm: "Did you read the spec from the file directly, or was it provided in my previous message?"
  If sub-agent says "provided in previous message" → independence violated. Restart review with fresh Agent call.

### Rule 3: Gate Resolution
```
IF status == "active" AND current_phase == "e3_human_gate":
  READ human_gate.yaml
  IF decision == "approved" AND no modifications:
    SET current_phase = "e4_compile_tasks"
    APPEND trace entry
  IF decision == "approved_with_modifications":
    DO NOT modify sdd_spec.yaml directly
    SET current_phase = "e8_spec_diff"
    APPEND trace entry
  IF decision == "revised" (send back to spec agent):
    KEEP current_phase = "e2_generate_spec" (re-enter)
    CLEAR sdd_spec.yaml (will be regenerated)
    APPEND trace entry
  IF decision == "rejected":
    SET status = "abandoned"
    APPEND trace entry
```

### Rule 4: Implementation Complete
```
IF status == "active" AND current_phase == "e5_implement":
  READ task_plan.yaml
  IF all tasks.status == "completed":
    SET current_phase = "e6_verify"
    APPEND trace entry
```

### Rule 5: Verification Resolution
```
IF status == "active" AND current_phase == "e6_verify":
  READ evidence_pack.yaml
  IF verdict.recommendation == "pass":
    SET current_phase = "e7_feedback"
    APPEND trace entry
  IF verdict.recommendation == "blocked":
    SET current_phase = "e5_implement"
    APPEND trace entry (with blocker notes)
```

### Rule 6: Feedback Resolution
```
IF status == "active" AND current_phase == "e7_feedback":
  IF feedback.type == "accepted":
    SET status = "completed"
    SET current_phase = null
    APPEND trace entry
  IF feedback.type == "implementation_defect":
    SET current_phase = "e5_implement"
    APPEND trace entry
  IF feedback.type == "spec_change":
    SET current_phase = "e8_spec_diff"
    APPEND trace entry
```

### Rule 7: Spec Diff Resolution
```
IF status == "active" AND current_phase == "e8_spec_diff":
  IF spec_diff.yaml exists:
    SET current_phase = "e3_human_gate"
    APPEND trace entry
```

## Determinism Guarantee

These rules are **ordered and exhaustive**. For any given `current_loop.yaml` state, exactly one rule applies. Claude Code must not apply judgment or interpretation — it must follow the rule that matches the state.
