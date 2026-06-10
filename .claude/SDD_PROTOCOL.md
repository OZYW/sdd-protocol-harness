# SDD Protocol — Claude Code Integration

This file provides instructions to Claude Code for enforcing the SDD Protocol in this project.

## Activation

This protocol is active when `.sdd/state/current_loop.yaml` exists and `status == "active"`.

## State Inspection Rule (ALWAYS DO THIS FIRST)

Before any file modification, code generation, or tool execution:

1. Read `.sdd/state/current_loop.yaml`
2. If `status == "idle"` or file does not exist: Operate normally (no SDD loop active).
3. If `status == "active"`: Check `current_phase` and follow the phase rules below.
4. If `status == "completed"` or `"abandoned"`: Operate normally.

## Phase Enforcement Rules

### E1_Capture — Intake Agent

- **Your action**: Call Agent tool with Intake Agent role (`skill/references/intake_agent.md`).
- **Input**: User's idea from `/sdd-start` command.
- **Output**: `idea_brief.yaml`
- **Auto-advance**: When `idea_brief.yaml` exists, advance to E2.

### E2_GenerateSpec — Spec Agent

- **Your action**: Call Agent tool with Spec Agent role.
- **Input**: `idea_brief.yaml`
- **Output**: `sdd_spec.yaml`
- **Auto-advance**: When `sdd_spec.yaml` exists, advance to E2_Review.

### E2_Review — Spec Review Agent (INDEPENDENT CALL)

- **Your action**: Call Agent tool with Spec Review Agent role in a FRESH context.
- **Critical**: The Spec Review Agent MUST read `sdd_spec.yaml` directly from file. Do NOT paste spec content into the Agent prompt.
- **Input**: File path to `sdd_spec.yaml` + `references/spec_review_agent.md`
- **Output**: Review result (pass / needs_revision)
- **On pass**: Advance to E3.
- **On needs_revision**: Return to E2_GenerateSpec with issue list.

### E3_HumanGate — STOP

- **Your action**: STOP all implementation. Present Human Gate.
- **Format**: Follow `.sdd/kernel/human_gate_format.md` exactly.
- **Critical**: Must be conversational. Do NOT ask user to review files.
- **Enforcement**: Before presenting, READ `human_gate_format.md` template. Your gate presentation MUST include ALL required sections. If you deviate, STOP and re-present using the exact format.
- **Environment Boundary Check**: If `environment_boundary.status != "accepted"`, include the Environment Boundary section in the gate (see `human_gate_format.md`).
- **Wait for**: Explicit user response.

**Response routing**:
- **"Approve" or "Yes"** (no modifications): Record `approved`. Advance to E4.
- **"Approve with changes" or "Yes, but X"** (any modification):
  - Record `revised_with_modifications`
  - Do NOT modify `sdd_spec.yaml` directly
  - Route to E8 (Spec Diff Agent) with user's modifications
  - Spec Diff Agent produces `spec_diff.yaml`
  - Return to E3 with spec diff summary for second approval
- **"Revise" or "Redo"** (send back to spec agent): Record `revise`. Return to E2.
- **"Reject" or "Cancel"**: Record `rejected`. Set status to `abandoned`.

### E4_CompileTasks — Task Compiler Agent

- **Your action**: Call Agent tool with Task Compiler Agent role.
- **Input**: Accepted `sdd_spec.yaml`
- **Output**: `task_plan.yaml`
- **Auto-advance**: When `task_plan.yaml` exists, advance to E5.
  - CHECK: `sdd_spec.yaml` must have `environment_boundary.status == "accepted"`. If not, STOP and present Environment Boundary Gate.

### E5_Implement — Implementation Agent

- **Your action**: Call Agent tool with Implementation Agent role for each task.
- **Input**: `task_plan.yaml`
- **Output**: Modified files, updated task statuses.
- **Auto-advance**: When all tasks complete, advance to E6.
- **Constraint**: Do NOT write code that is not in the task plan.

### E6_Verify — Verification Agent

- **Your action**: Call Agent tool with Verification Agent role.
- **Input**: `sdd_spec.yaml` acceptance criteria, completed task plan.
- **Output**: `evidence_pack.yaml`
- **On pass**: Advance to E7.
- **On blocked**: Return to E5 (with blocker details).

### E7_Feedback — STOP

- **Your action**: STOP. Present evidence summary. Await user feedback.
- **Risk Check**: Before recommending ANY post-loop action (e.g., "npm install", "git commit"), check `.sdd/kernel/risk_matrix.md`. If the action is **High Risk**, explicitly flag it as requiring human approval. Do NOT present High Risk actions as routine next steps.
- **human_acceptance criteria**: If any criterion uses `verification_method: human_acceptance` and has NOT been explicitly confirmed by the user, do NOT offer [接受] without warning. Instead: "A-020 requires visual confirmation. You may [接受] now and verify visually later, or [启动应用] first then确认."
- **On accepted**: Complete loop.
- **On implementation_defect**: Return to E5.
  - Create `.sdd/artifacts/loops/{LOOP_ID}/fix_verification.yaml` documenting the defect, fix approach, and re-verification plan.
- **On spec_change**: Advance to E8.

### E8_SpecDiff — Spec Diff Agent

- **Your action**: Call Agent tool with Spec Diff Agent role.
- **Input**: User feedback, current `sdd_spec.yaml`.
- **Output**: `spec_diff.yaml`.
- **Auto-advance**: When `spec_diff.yaml` exists, route to E3 (Human Gate).

## Phase Transition Trace Rule (ALWAYS DO THIS)

After EVERY phase transition, you MUST append an entry to `.sdd/state/phase_history.yaml`:

```yaml
- timestamp: "{ISO 8601}"
  loop_id: "{LXXX}"
  phase: "{phase_name}"
  triggered_by: "auto_advance | user_command | gate_resolution | feedback_resolution | protocol_rescue"
  condition: "{what triggered this transition}"
  agent_role: "{role_name}"
  decision: "continue | human_gate | blocked"
  evidence_ref: "{path to artifact}"
  notes: "{brief description}"
```

Failure to append trace entries violates Rule 6 and destroys auditability.

## Critical Constraints

1. **No code without accepted spec**: If `sdd_spec.yaml` does not exist or status != "accepted", do NOT write implementation code.
2. **Human Gate is mandatory**: Never skip E3. Never present files for review at a gate.
3. **Evidence before completion**: Never claim a loop is complete without `evidence_pack.yaml`.
4. **Spec diff before product change**: If user feedback changes scope/intent/behavior, produce `spec_diff.yaml` FIRST.
5. **Append-only trace**: Every phase transition appends to execution trace. Never modify existing entries.
6. **Single active loop**: If a new `/sdd-start` arrives while a loop is active, present choice: abandon current, continue current, or queue.
7. **Environment boundary must be defined**: Before writing code, `sdd_spec.yaml` must have `environment_boundary.status == "accepted"`. Do NOT install dependencies into global Python. Use project `.venv/` only.
8. **Git operations need approval**: `git commit`, `git push`, `git merge`, `git rebase` require explicit human approval. `git add`, `git status`, `git diff` are low-risk and may proceed.
9. **Risk matrix governs all actions**: Before any action, check `.sdd/kernel/risk_matrix.md` for the action's risk level and required decision.

## Commands

- `/sdd-start <idea>` — Start a new SDD loop with the given idea.
- `/sdd-status` — Show current loop state, phase, and pending decisions.
- `/sdd-continue` — Resume execution from current phase (after a gate or blocker).
- `/sdd-abandon` — Abandon current loop (requires confirmation).
