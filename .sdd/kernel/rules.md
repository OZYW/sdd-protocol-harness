# SDD Protocol — Core Rules

## Rule 1: State Inspection Before Action

Before any file modification, code generation, or tool execution, Claude Code MUST:

1. Read `.sdd/state/current_loop.yaml`
2. If `status == "active"`, check `current_phase`
3. Only perform actions permitted by the current phase

## Rule 2: No Code Without Accepted Spec

Claude Code MUST NOT write implementation code unless:
- An `sdd_spec.yaml` exists with `status == "accepted"`
- A `task_plan.yaml` exists mapping tasks to spec clauses
- The current task is explicitly in the task plan

Emergency bypass: User explicitly commands "bypass SDD protocol" — but this MUST be recorded in the execution trace with a `forbidden` decision marker.

## Rule 3: Human Gate Is Mandatory

When `current_phase == "e3_human_gate"`, Claude Code MUST:
1. STOP all implementation activity
2. Read `human_gate.yaml` template
3. Present the gate in CONVERSATIONAL format (see `human_gate_format.md`)
4. Wait for explicit user response
5. Record response in `human_gate.yaml`
6. Only then apply Rule 3 from `phases.md`

## Rule 4: Evidence Before Completion

Claude Code MUST NOT claim a loop is complete unless:
- `evidence_pack.yaml` exists
- All acceptance criteria have corresponding evidence entries
- `verdict.all_criteria_met == true` OR `verdict.recommendation` is explicitly justified

## Rule 5: Spec Diff Before Product Change

If user feedback changes scope, intent, or acceptance criteria:
1. Claude Code MUST produce `spec_diff.yaml` FIRST
2. Route to Human Gate (E3)
3. Only after approval, implement the code changes

If feedback is purely an implementation defect (bug, typo, missing file):
1. Route directly to E5 (Implementation)
2. No spec diff required
3. But evidence must be collected on the fix

## Rule 6: Append-Only Trace

The execution trace MUST:
- Only append new entries
- Never delete, modify, or reorder existing entries
- Include timestamps in ISO 8601 format
- Include the exact decision that led to each phase transition

## Rule 7: Determinism

Given the same `current_loop.yaml` content, Claude Code MUST reach the same phase decision. There is no room for "it depends" or "usually."

If the state does not match any rule in `phases.md`:
- Decision = `blocked`
- Action = Stop and report "State does not match any known transition rule"
- Do NOT guess or invent a transition

## Rule 8: Single Active Loop

Phase 1 supports exactly ONE active loop at a time.

If user triggers `/sdd-start` while another loop is `status == "active"`:
- Decision = `human_gate`
- Present: "Loop LXXX is still active at phase EY. Abandon it, or complete it first?"
- Options: [Abandon current] [Continue current] [Queue new]

If user selects [Queue new]: Add to queue. Do not start until current loop completes or is abandoned.

## Rule 9: Review Agent Independence

Any agent whose role includes "review" in its name MUST be invoked as a separate `Agent` tool call with no shared context from the agent whose output it reviews.

**Prohibited**: Asking the same agent instance to "now review what you just wrote."
**Required**: Fresh Agent call with role prompt + artifact file reference only.

**Affected roles**:
- Spec Review Agent (reviews Spec Agent output)
- Verification Agent (reviews Implementation Agent output)

**Exception**: None in Phase 1. Single-session execution is accepted only when the tool ecosystem does not support true isolation. When true isolation is available (e.g., multiple Claude Code sessions), it MUST be used.

## Rule 10: No Direct Spec Modification After Gate Approval

Once a spec has been presented at a Human Gate (E3), it MUST NOT be directly modified by the Host or any agent based on user feedback.

**Prohibited**: Host reads Human Gate response "approved with changes" and directly edits `sdd_spec.yaml`.
**Required**: Host routes ALL modifications through Feedback Agent → Spec Diff Agent → New Human Gate.

**Procedure for gate modifications**:
1. User responds with modifications at Human Gate
2. Host records response in `human_gate.yaml` as `revised_with_modifications`
3. Host calls Feedback Agent to classify modifications
4. Host calls Spec Diff Agent to produce `spec_diff.yaml`
5. Host presents NEW Human Gate with the spec diff summary
6. Only after second Human Gate approval, apply changes to `sdd_spec.yaml`
7. Increment spec version number

**Exception — Emergency Fast-Track**:
If user explicitly says "skip spec diff, apply changes directly":
- Decision = `forbidden_override`
- Record user's exact words in execution trace
- Apply changes directly
- Increment spec version number
- Mark as `emergency_bypass: true` in spec metadata

## Rule 11: Environment Boundary Must Be Defined Before Implementation

Before writing any implementation code, the Environment Boundary in `sdd_spec.yaml` MUST be defined and accepted.

**Required fields**:
- `runtime_carrier`: What language/runtime (python, nodejs, go, rust)
- `language_version`: Which version (3.12, 20, 1.22)
- `package_manager`: Which tool manages dependencies (uv, pip, npm, cargo)
- `commands.test`: How to run tests
- `commands.run`: How to run the application

**Environment constraints**:
- Implementation Agent MUST NOT install dependencies into global/system Python
- Implementation Agent MUST use the project's `.venv/` or declared virtual environment
- Implementation Agent MUST respect the declared `dependency_file` format
- Implementation Agent MUST NOT introduce dependencies not in the accepted spec

**If environment boundary is `not_selected`**:
- Decision = `blocked`
- Action = Route to Spec Agent to propose environment boundary
- Do NOT proceed to implementation

## Rule 12: Git Operations Require Explicit Human Approval

The following Git operations are HIGH RISK and require explicit `human_gate` approval:

| Operation | Risk Level | Required Approval |
|-----------|-----------|-------------------|
| `git commit` | High | Explicit human approval |
| `git push` | High | Explicit human approval |
| `git merge` | High | Explicit human approval |
| `git rebase` | High | Explicit human approval |
| `git reset --hard` | High | Explicit human approval |
| `git branch -D` | High | Explicit human approval |
| `git add` | Low | Can proceed automatically |
| `git status` | Low | Can proceed automatically |
| `git diff` | Low | Can proceed automatically |
| `git log` | Low | Can proceed automatically |

**Git hygiene rules**:
- Every commit MUST reference a spec clause or task ID in its message
- Commit messages SHOULD follow: `[{spec_id}] {task_id}: {description}`
- Do NOT commit on a dirty worktree without checking `git status`
- Do NOT push without confirming tests pass

**If user requests a Git operation**:
1. Check risk level in table above
2. If High Risk → `human_gate` with: "You are requesting {operation}. This will {impact}. Approve?"
3. If Low Risk → proceed, but record in execution trace
