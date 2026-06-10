# Task Plan 001: Claude Code SDD Harness — Phase 1 Implementation

## Metadata

- Plan ID: TP-001
- Source Spec: SDD-001 v0.2
- Status: accepted
- Date: 2026-06-08

## Scope

Phase 1: Passive trigger, filesystem state, embedded Protocol Kernel in CLAUDE.md.
No active intent interception. No external dependencies. No Python runtime.

---

## Task 1: Project Directory Structure

**Spec clause**: B-001 (foundation)
**Agent role**: Implementation Agent
**Description**: Create the harness directory layout under `.sdd/` and `.claude/SDD_PROTOCOL.md`.

**Deliverables**:
```
.sdd/
  state/
    current_loop.yaml    # Loop state marker
    phase_history.yaml   # Append-only phase transitions
  artifacts/
    templates/           # YAML schema templates for each artifact type
      idea_brief.yaml
      sdd_spec.yaml
      human_gate.yaml
      task_plan.yaml
      evidence_pack.yaml
      spec_diff.yaml
      execution_trace.yaml
  handoffs/
    # Empty initially; populated during loops
  kernel/
    rules.md             # Protocol Kernel rules (human-readable)
    phases.md            # Phase definitions and transitions
    decisions.md         # Decision type definitions
.claude/
  SDD_PROTOCOL.md        # Claude Code integration instructions
```

**Acceptance criteria**: A-001 — Files exist at expected paths.

---

## Task 2: Artifact Schema Templates

**Spec clause**: B-002, B-003, B-005, B-007, B-008, B-009
**Agent role**: Spec Agent + Implementation Agent
**Description**: Define YAML schema templates for all artifact types. Each template must include:
- Required metadata fields (ID, version, timestamp, source trace)
- Validation constraints (which fields must be present)
- Human-readable comments

**Deliverables**:
- `.sdd/artifacts/templates/idea_brief.yaml`
- `.sdd/artifacts/templates/sdd_spec.yaml`
- `.sdd/artifacts/templates/human_gate.yaml`
- `.sdd/artifacts/templates/task_plan.yaml`
- `.sdd/artifacts/templates/evidence_pack.yaml`
- `.sdd/artifacts/templates/spec_diff.yaml`
- `.sdd/artifacts/templates/execution_trace.yaml`

**Acceptance criteria**: A-003 — Each template is valid YAML with all required fields populated.

---

## Task 3: Protocol Kernel — Embedded Rules

**Spec clause**: B-010
**Agent role**: Spec Agent + Implementation Agent
**Description**: Write the Protocol Kernel rules as human-readable markdown that Claude Code follows. Since Phase 1 has no Python runtime, the Kernel is "executed" by Claude Code reading these rules and applying them.

**Deliverables**:
- `.sdd/kernel/phases.md` — Phase definitions (E1-E8), entry conditions, exit conditions
- `.sdd/kernel/rules.md` — State transition rules, determinism guarantees
- `.sdd/kernel/decisions.md` — Decision types (continue, human_gate, blocked, backlog, forbidden)

**Key rule**: Given the same `current_loop.yaml` content, Claude Code must always reach the same next phase decision.

**Acceptance criteria**: A-005 — Same state input produces same phase decision.

---

## Task 4: Role Prompt Templates

**Spec clause**: B-002, B-003, B-005, B-006, B-007, B-008
**Agent role**: Spec Agent
**Description**: Write role-specific prompt templates that Claude Code injects into Agent tool calls.

**Deliverables** (stored in skill `references/` directory):
- `references/intake_agent.md` — Captures natural language idea into `idea_brief.yaml`
- `references/spec_agent.md` — Converts `idea_brief.yaml` into `sdd_spec.yaml`
- `references/spec_review_agent.md` — Checks `sdd_spec.yaml` for gaps/conflicts
- `references/task_compiler_agent.md` — Converts `sdd_spec.yaml` into `task_plan.yaml`
- `references/implementation_agent.md` — Executes tasks from `task_plan.yaml`
- `references/verification_agent.md` — Collects evidence into `evidence_pack.yaml`
- `references/feedback_agent.md` — Classifies user feedback
- `references/spec_diff_agent.md` — Produces `spec_diff.yaml`

**Each prompt must include**:
- Role goal and constraints
- Expected input (handoff artifact)
- Expected output (artifact format)
- What NOT to do (e.g., "do not write code without a task plan")

**Acceptance criteria**: A-006 — Each role prompt is self-contained and references correct artifacts.

---

## Task 5: Human Gate Format

**Spec clause**: B-004
**Agent role**: Spec Agent
**Description**: Define the conversational Human Gate format that Claude Code presents to users.

**Deliverables**:
- `.sdd/kernel/human_gate_format.md` — Template for gate presentation
- Must include: current state, decision needed, recommended option, alternatives, expected impact, rollback path, consequence of no decision
- Must explicitly state: "You do not need to review files. Just confirm intent, behavior, or risk."

**Acceptance criteria**: A-004, A-010 — Gate is conversational; user is not asked to review files.

---

## Task 6: Claude Code Integration (CLAUDE.md + Skill)

**Spec clause**: B-001, B-006, B-010
**Agent role**: Implementation Agent
**Description**: Write the files that make Claude Code aware of and enforce the SDD Protocol.

**Deliverables**:

1. `.claude/SDD_PROTOCOL.md`:
   - "This project uses SDD Protocol"
   - State check rule: "Before any action, read `.sdd/state/current_loop.yaml`"
   - Gate enforcement: "If phase requires human_gate, stop and present gate format"
   - Evidence rule: "Before claiming completion, collect evidence"
   - Spec-diff rule: "No code changes without accepted spec diff"
   - Phase transition logic embedded as markdown rules

2. `SKILL.md` (user-level skill at `~/.claude/skills/sdd-protocol/`):
   - Skill name and description
   - Commands: `/sdd-start`, `/sdd-status`, `/sdd-continue`, `/sdd-abandon`
   - Command routing table
   - Reference to role prompts in `references/`

**Acceptance criteria**: A-001 — Installing harness means these files exist and are readable by Claude Code.

---

## Task 7: Evidence Collection Rules

**Spec clause**: B-007
**Agent role**: Spec Agent
**Description**: Define what constitutes acceptable evidence for each verification method.

**Deliverables**:
- `.sdd/kernel/evidence_rules.md`:
  - A-layer evidence types: file existence, git diff, command output, test results, screenshots, logs
  - B-layer evidence types: docs, release notes, external references (may NOT promote status)
  - Per-method requirements: what evidence is required for `test`, `human_acceptance`, `screenshot`, etc.

**Acceptance criteria**: A-007 — Evidence rules are explicit and checkable.

---

## Task 8: Execution Trace Mechanism

**Spec clause**: B-009
**Agent role**: Implementation Agent
**Description**: Implement append-only execution trace recording.

**Deliverables**:
- `.sdd/artifacts/templates/execution_trace.yaml` — Schema for trace entries
- Rule in `.sdd/kernel/rules.md`: "Every phase transition appends a trace entry"
- Trace entry fields: timestamp, loop_id, phase, agent_role, decision, evidence_ref

**Acceptance criteria**: A-009 — Trace file is append-only; timestamps are monotonic.

---

## Task 9: Spec Diff Rules

**Spec clause**: B-008
**Agent role**: Spec Agent
**Description**: Define when and how spec diffs are produced.

**Deliverables**:
- `.sdd/kernel/spec_diff_rules.md`:
  - Trigger conditions: user feedback changes scope/intent/acceptance criteria
  - Format: `spec_diff.yaml` template with before/after fields
  - Routing: spec diff goes to Human Gate (E3) before code changes
  - Emergency bypass: allowed with explicit user command + audit trail

**Acceptance criteria**: A-008 — Spec diff is created and routed through gate.

---

## Task 10: Integration Test — Dry Run

**Spec clause**: All
**Agent role**: Verification Agent
**Description**: Run a complete dry-run loop using the harness on a toy request.

**Scenario**: "Build a function that reverses a string"

**Expected trace**:
1. `/sdd-start build a function that reverses a string`
2. E1: `idea_brief.yaml` created
3. E2: `sdd_spec.yaml` created
4. E3: Human Gate presented (user approves)
5. E4: `task_plan.yaml` created
6. E5: Implementation Agent writes code
7. E6: Verification Agent collects evidence (test output)
8. E7: User accepts
9. Loop completes

**Acceptance criteria**: All A-001 through A-010 pass.

---

## Dependencies

```
Task 1 (Structure)
  └── Task 2 (Schemas)
        └── Task 3 (Kernel)
              ├── Task 4 (Roles)
              ├── Task 5 (Gate)
              ├── Task 7 (Evidence)
              ├── Task 8 (Trace)
              └── Task 9 (Spec Diff)
                    └── Task 6 (Integration)
                          └── Task 10 (Dry Run)
```

## Assignment Priority

| Order | Task | Rationale |
|-------|------|-----------|
| 1 | Task 1 + Task 2 | Foundation: directory and schemas |
| 2 | Task 3 | Kernel rules enable everything else |
| 3 | Task 4 + Task 5 + Task 7 + Task 8 + Task 9 | Parallel: independent role definitions |
| 4 | Task 6 | Integration: brings everything together |
| 5 | Task 10 | Validation: proves it works |
