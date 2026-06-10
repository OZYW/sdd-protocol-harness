# SDD Spec 001: Claude Code SDD Harness

## Metadata

- Spec ID: SDD-001
- Version: 0.4
- Status: accepted
- Source Idea ID: IB-001
- Spec Agent: Claude Code

## Product Intent

A filesystem-based governance layer that makes Claude Code automatically follow the SDD Protocol during any development task. The human user speaks naturally; the harness ensures structured artifacts are produced, human gates are respected, and product definition changes are explicit before code changes.

## Goals

1. **Explicit Loop Trigger**: The harness starts a new SDD loop when the user explicitly requests it (e.g., `/sdd-start` or similar command), not by auto-intercepting natural language intent.
2. **Structured Artifact Generation**: Every phase produces a machine-readable artifact (YAML) and a human-readable summary (Markdown).
3. **Enforced Human Gates**: Claude Code stops at defined gates with a conversational summary, not a file review request.
4. **Role-Routed Agent Calls**: Tasks are dispatched to Claude Code Agent tools with role-specific prompts and handoff artifacts.
5. **Evidence Collection**: No completion claim without collected evidence.
6. **Spec-Diff Before Code**: Product definition changes must be explicit before implementation changes.

## Non-Goals

- Do not build a standalone application, web service, or IDE plugin.
- Do not replace or modify Claude Code itself.
- Do not support editors other than Claude Code in Phase 1.
- Do not automate human gate decisions.
- Do not introduce package dependencies for the harness core.

## Actors

| Actor | Role | Needs |
|-------|------|-------|
| Human User | Provides ideas, confirms intent, approves risk, accepts behavior | Conversational surface, no file review by default |
| Claude Code (Host) | Executes the harness, calls Agent tools, reads/writes files | Clear instructions in CLAUDE.md, structured artifact access |
| Protocol Kernel | Decides next step based on filesystem state | Deterministic rules, inspectable state |
| Agent Roles | Execute phase-specific work via Claude Code Agent tool | Role prompt, handoff artifact, acceptance criteria |

## Domain Terms

| Term | Meaning |
|------|---------|
| Harness | The filesystem-based governance layer installed in a project |
| Loop | One complete SDD cycle: Idea -> Spec -> Gate -> Tasks -> Implement -> Verify -> Feedback -> Diff |
| Phase | A named stage within a loop (e.g., E1_Capture, E2_GenerateSpec) |
| Artifact | A structured file produced by an agent role |
| Handoff | The transfer of artifact + decision + evidence + open issues between roles |
| Gate | A required human confirmation point |
| State Marker | A small file that records the current phase and loop ID |

## Functional Behavior

| ID | Behavior | Source intent | Acceptance signal |
|----|----------|---------------|-------------------|
| B-001 | Harness starts new SDD loop on explicit user trigger (`/sdd-start` or equivalent) | IB-001 | State marker created with phase E1 |
| B-002 | Harness generates an Idea Brief artifact from natural language input | IB-001 | `idea_brief.yaml` exists with all required fields |
| B-003 | Harness converts Idea Brief into SDD Spec candidate | IB-001 | `sdd_spec.yaml` exists, linked to source idea |
| B-004 | Harness stops at Human Gate with conversational summary | IB-001 | Execution pauses, user receives gate summary, not file list |
| B-005 | Harness compiles accepted spec into Task Plan | IB-001 | `task_plan.yaml` exists with tasks mapped to spec clauses |
| B-006 | Harness routes each task to Agent tool with role prompt + handoff | IB-001 | Agent calls include role context and artifact references |
| B-007 | Harness collects verification evidence before completion claim | IB-001 | `evidence_pack.yaml` exists with A-layer evidence |
| B-008 | Harness converts feedback into Spec Diff before code changes | IB-001 | `spec_diff.yaml` exists when product definition changes |
| B-009 | Harness maintains execution trace for Protocol Fitness Audit | IB-001 | `execution_trace.yaml` is append-only, time-ordered |
| B-010 | Protocol Kernel makes deterministic phase decisions from filesystem state | Known preferences | Same state always yields same decision |

## State or Data Model

### Loop State

```yaml
loop:
  loop_id: "L001"
  status: active | completed | abandoned
  current_phase: e1_capture | e2_generate_spec | e3_human_gate | e4_compile_tasks | e5_implement | e6_verify | e7_feedback | e8_spec_diff
  created_at: "2026-06-08T10:00:00Z"
  updated_at: "2026-06-08T10:30:00Z"
```

### Phase Transition Rules (Deterministic)

```
E1_Capture -> E2_GenerateSpec     [auto: idea_brief.yaml complete]
E2_GenerateSpec -> E3_HumanGate   [auto: sdd_spec.yaml complete]
E3_HumanGate -> E4_CompileTasks   [condition: human_gate.decision == approved]
E3_HumanGate -> E2_GenerateSpec   [condition: human_gate.decision == revise]
E4_CompileTasks -> E5_Implement   [auto: task_plan.yaml complete]
E5_Implement -> E6_Verify         [auto: all tasks claimed complete]
E6_Verify -> E7_Feedback          [condition: evidence_pack.accepted == true]
E6_Verify -> E5_Implement         [condition: evidence_pack.defects_found == true]
E7_Feedback -> E8_SpecDiff        [condition: feedback.type == spec_change]
E7_Feedback -> E5_Implement       [condition: feedback.type == implementation_defect]
E7_Feedback -> completed          [condition: feedback.type == accepted]
E8_SpecDiff -> E3_HumanGate       [auto: spec_diff.yaml complete]
```

## User Flow

1. User opens Claude Code in a project with the harness installed.
2. User says: `/sdd-start build me a todo list app`.
3. Claude Code (host) checks `.sdd/state/current_loop.yaml`. No active loop -> starts Loop L001 at E1.
4. Claude Code calls Agent tool (Intake Agent) -> produces `idea_brief.yaml`.
5. Protocol Kernel advances to E2 -> calls Spec Agent -> produces `sdd_spec.yaml`.
6. Protocol Kernel advances to E3 -> stops. Host presents conversational Human Gate summary.
7. User approves. Kernel advances to E4 -> calls Task Compiler Agent -> produces `task_plan.yaml`.
8. Kernel advances to E5 -> routes each task to Implementation Agent via Agent tool.
9. Kernel advances to E6 -> calls Verification Agent -> produces `evidence_pack.yaml`.
10. Host presents evidence summary. User accepts or provides feedback.
11. If feedback changes product definition -> Kernel routes to E8 Spec Diff Agent -> back to E3.
12. If feedback is implementation defect -> Kernel routes back to E5.
13. If user accepts -> Loop completes.

## Acceptance Criteria

| ID | Criterion | Verification method |
|----|-----------|---------------------|
| A-001 | Harness can be installed in a project by creating the `.claude/SDD_PROTOCOL.md` and template files | `test` - run install script, verify files exist |
| A-002 | Explicit trigger (`/sdd-start`) starts a new SDD loop | `test` - simulate input, verify state marker |
| A-003 | Each phase produces a valid YAML artifact | `test` - validate against schema |
| A-004 | Human Gate stops execution with conversational summary | `human_acceptance` - test with real user |
| A-005 | Protocol Kernel makes deterministic decisions | `test` - same input, same output across 10 runs |
| A-006 | Agent calls include role-specific prompts and handoff artifacts | `test` - inspect Agent tool call arguments |
| A-007 | Evidence is collected before completion claim | `test` - verify evidence_pack.yaml exists before loop completion |
| A-008 | Spec changes require explicit diff before code changes | `test` - simulate feedback, verify spec_diff.yaml created |
| A-009 | Execution trace is append-only and time-ordered | `test` - verify trace file monotonicity |
| A-010 | Human user is never asked to review files by default | `human_acceptance` - observe gate presentation |

## Environment Boundary

- Runtime carrier: Python 3.11+ (for Protocol Kernel)
- Package manager: None for core (stdlib only); optional pytest for tests
- External services: None
- Data persistence: Filesystem only (YAML, Markdown, text files)
- Deployment target: None — installed per project
- Current status: proposed

## Risks

| Risk | Level | Mitigation | Human approval needed |
|------|-------|------------|----------------------|
| Protocol Kernel complexity grows beyond deterministic rules | medium | Limit Kernel to phase transitions only; keep business logic in agent prompts | no |
| Agent tool context limits prevent full handoff artifact inclusion | medium | Use file references in prompts; include only summary in context | no |
| User finds harness too restrictive and disables it | high | Make harness opt-in per project; allow emergency bypass with audit trail | yes |
| Filesystem I/O becomes bottleneck | low | Artifact files are small (< 10KB); state markers are tiny | no |
| YAML schema evolution breaks existing artifacts | medium | Version all schemas; include schema version in artifact metadata | no |

## Architecture Decisions

### Decision 1: Layered Hybrid Architecture

**Chosen**: Three-layer design — Skill (trigger/interface) + Files (state/persistence) + CLAUDE.md (constraints/integration).

**Rationale**: Skill provides command interface; files provide auditability; CLAUDE.md provides project-level constraints. No single layer is sufficient.

### Decision 2: User-Level Skill Installation

**Chosen**: Skill installed at `~/.claude/skills/sdd-protocol/` (user-level), not project-level.

**Rationale**: Core value is cross-project methodology reuse. Project-specific state lives in `.sdd/` directory within each project.

### Decision 3: Passive Trigger for Phase 1

**Chosen**: User must explicitly trigger SDD loop via `/sdd-start` or similar command. Active intent interception (auto-detect "build me an app") is deferred to Phase 2.

**Rationale**: Reduces Phase 1 scope and risk. Explicit opt-in per loop is less surprising. Skill can be upgraded to active trigger without changing file state layer.

## Open Questions

1. ~~Q1: Should the Protocol Kernel be a Python script or embedded in CLAUDE.md?~~
   - **Resolved**: Phase 1 uses embedded logic in CLAUDE.md. No runtime dependency.

2. **Q2**: How does the harness handle multiple concurrent loops (e.g., user starts a new idea while previous loop is at E3)?
   - Impact: Affects state model design.
   - Suggestion: Phase 1 supports single active loop only. Queue or parallel loops are Phase 2.

3. **Q3**: What is the "install" experience? Copy files? A CLI command? A Claude Code slash command?
   - Impact: Affects adoption friction.
   - Suggestion: Phase 1 is "copy the `harness/` directory into your project". Phase 2 could be a shell script or Claude Code skill command.

## Version History

| Version | Date | Change | Triggered By |
|---------|------|--------|-------------|
| 0.1 | 2026-06-08 | Initial spec draft | IB-001 |
| 0.2 | 2026-06-08 | Approved with modification (passive trigger for Phase 1) | Human Gate 001 |
| 0.3 | 2026-06-08 | Added F1 (Review Agent independence) and F2 (Gate modification routing) corrections | Protocol Fitness Audit 001 |

## Traceability

| Spec item | Source idea / feedback | Downstream task | Evidence |
|-----------|------------------------|-----------------|----------|
| B-001 to B-010 | IB-001 | TBD | TBD |
| State model | Known preferences | TBD | TBD |
| Phase transitions | PROTOCOL_KERNEL_v0 | TBD | TBD |
| Human Gate format | PROTOCOL_KERNEL_v0 | TBD | TBD |
| F1: Review independence | PFA-001 Finding F1 | SPEC_DIFF_F1 | Applied to phases.md, rules.md, SDD_PROTOCOL.md, spec_review_agent.md |
| F2: Gate diff routing | PFA-001 Finding F2 | SPEC_DIFF_F2 | Applied to rules.md, phases.md, SDD_PROTOCOL.md, feedback_agent.md, spec_diff_rules.md, human_gate_format.md |
