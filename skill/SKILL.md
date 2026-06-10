# SDD Protocol — Claude Code Skill

A governance layer that enforces structured artifacts, human gates, evidence collection, and spec-diffs before code changes.

## When to Use This Skill

Use this skill when the user explicitly invokes SDD Protocol commands:
- `/sdd-start <idea>` — Begin a new SDD loop
- `/sdd-status` — Check current loop state
- `/sdd-continue` — Resume from current phase
- `/sdd-abandon` — Abandon current loop

Also use when the user mentions "spec-driven", "SDD protocol", "start a spec loop", or similar.

## State Check (Always Do This First)

Read `.sdd/state/current_loop.yaml` if it exists.

- **`status: idle` or file missing** → No active loop. User's `/sdd-start` command starts a new one.
- **`status: active` and `current_phase: e3_human_gate`** → STOP. Present gate summary per `.sdd/kernel/human_gate_format.md`.
- **`status: active` and `current_phase: e7_feedback`** → STOP. Present evidence summary and await feedback.
- **`status: active` and any other phase** → Continue from current phase per `.claude/SDD_PROTOCOL.md`.
- **`status: completed` or `abandoned`** → Normal operation. User may start a new loop.

## Commands

### `/sdd-start <idea>`

Start a new SDD loop with the given natural language idea.

1. Check `current_loop.yaml`. If `status == "active"`, present:
   - "Loop {loop_id} is active at phase {current_phase}. What would you like to do?"
   - Options: [Abandon current] [Continue current] [Queue new]
2. If idle or user chooses to proceed:
   - Create new loop with sequential ID
   - Set `status: active`, `current_phase: e1_capture`
   - Call Intake Agent (`references/intake_agent.md`)
   - Follow phase transitions per `.sdd/kernel/phases.md`

### `/sdd-status`

Show current loop state in a human-readable summary.

```
Current SDD Loop: {loop_id}
Status: {status}
Phase: {current_phase}
{if active}:
  Active artifact: {most recent artifact}
  Pending: {what needs to happen next}
  {if at gate}: Waiting for your decision
```

### `/sdd-continue`

Resume execution from the current phase.

Use when:
- User approved a gate and wants to continue
- User resolved a blocker
- Loop was interrupted and needs to resume

Read `current_loop.yaml`, identify phase, execute corresponding rule from `.claude/SDD_PROTOCOL.md`.

### `/sdd-abandon`

Abandon the current loop.

1. Confirm: "Abandon loop {loop_id}? All progress will be preserved in artifacts but no code will be implemented."
2. If confirmed:
   - Set `status: abandoned`
   - Append trace entry
   - Resume normal operation

## Role Prompts

Agent tool calls MUST include the appropriate role prompt from `references/`:

| Phase | Role | Prompt File |
|-------|------|-------------|
| E1 | Intake Agent | `references/intake_agent.md` |
| E2 | Spec Agent | `references/spec_agent.md` |
| E2 (review) | Spec Review Agent | `references/spec_review_agent.md` |
| E4 | Task Compiler Agent | `references/task_compiler_agent.md` |
| E5 | Implementation Agent | `references/implementation_agent.md` |
| E6 | Verification Agent | `references/verification_agent.md` |
| E7 | Feedback Agent | `references/feedback_agent.md` |
| E8 | Spec Diff Agent | `references/spec_diff_agent.md` |

## Rules Reference

- Phase transitions: `.sdd/kernel/phases.md`
- Core rules: `.sdd/kernel/rules.md`
- Decision types: `.sdd/kernel/decisions.md`
- Human gate format: `.sdd/kernel/human_gate_format.md`
- Evidence rules: `.sdd/kernel/evidence_rules.md`
- Spec diff rules: `.sdd/kernel/spec_diff_rules.md`
- Claude Code integration: `.claude/SDD_PROTOCOL.md`
