# SDD Protocol — Decision Types

Every agent step, state transition, and user interaction MUST resolve to one of these five decision types.

## Decision Types

### `continue`
- **Meaning**: Proceed under accepted protocol and current spec.
- **When to use**: Phase transitions where all conditions are met (auto-advance rules).
- **Human involvement**: None.
- **Example**: E1 complete → E2; E4 complete → E5.

### `human_gate`
- **Meaning**: Stop and request human confirmation.
- **When to use**: Spec approval, spec diff approval, ambiguous feedback, conflict between artifacts.
- **Human involvement**: Required. Must provide conversational summary, not file review.
- **Example**: E2 complete → E3; E8 complete → E3.

### `blocked`
- **Meaning**: Stop because required input or evidence is missing.
- **When to use**: Artifact expected but not found, state does not match any transition rule, verification failed with no clear fix path.
- **Human involvement**: Optional. Agent should attempt to unblock first. If cannot, escalate to human.
- **Example**: E5 complete but task plan shows incomplete tasks; expected evidence missing.

### `backlog`
- **Meaning**: Record as future work outside the current loop.
- **When to use**: Feature request outside current scope, non-blocking question, optimization not tied to acceptance criteria.
- **Human involvement**: Inform user what was backlogged and why.
- **Example**: User says "also make it support dark mode" during an unrelated implementation task.

### `forbidden`
- **Meaning**: Reject because the action violates active constraints.
- **When to use**: Code change without accepted spec, history rewrite without approval, commit without approval, bypassing human gate.
- **Human involvement**: Inform user why action is forbidden and what the correct path is.
- **Example**: User says "just change the code" while at E3 (unapproved spec).

## Decision Routing

| Decision | Next Action | State Change | User Notified? |
|----------|-------------|--------------|----------------|
| `continue` | Proceed to next phase | Yes (advance) | No (silent) |
| `human_gate` | Present gate summary | No (hold) | Yes (explicit) |
| `blocked` | Report blocker, attempt resolution | No (hold) | Yes if unresolvable |
| `backlog` | Record in backlog, continue current | No (hold scope) | Yes (inform) |
| `forbidden` | Refuse action, explain correct path | No (hold) | Yes (explicit) |

## Forbidden Overrides

The ONLY way to override a `forbidden` decision is:
1. User explicitly states: "I understand this violates SDD Protocol and I want to proceed anyway"
2. Record the override in execution trace with `decision: forbidden_override`
3. Include user's exact words as evidence
4. Continue with user's command

This is an AUDIT trail, not a recommendation. Overuse indicates protocol friction that should be recorded for Phase 5 revision.
