# SDD Protocol — Risk Matrix

## Purpose

Maps every common development action to its risk level and required decision type. Host MUST apply this matrix before allowing any action during an active SDD loop.

## Risk Levels

| Level | Color | Meaning | Decision |
|-------|-------|---------|----------|
| **Low** | Green | Safe to proceed automatically when linked to accepted spec | `continue` |
| **Medium** | Yellow | Requires short summary and confirmation | `human_gate` (summary only) |
| **High** | Red | Requires explicit approval with rollback path | `human_gate` (full gate format) |
| **Forbidden** | Black | Violates active constraints | `forbidden` |

## File Operations

| Action | Risk | Condition | Decision |
|--------|------|-----------|----------|
| Create new file | Low | Within task scope | `continue` |
| Edit existing file | Low | Within task scope | `continue` |
| Delete file | **High** | Always | `human_gate` |
| Rename file | Medium | Within task scope | `human_gate` (summary) |
| Change file permissions | **High** | Always | `human_gate` |
| Write outside project dir | **Forbidden** | Always | `forbidden` |

## Code Operations

| Action | Risk | Condition | Decision |
|--------|------|-----------|----------|
| Add function/method | Low | Maps to accepted spec clause | `continue` |
| Add class/module | Low | Maps to accepted spec clause | `continue` |
| Change function signature | Medium | Changes API contract | `human_gate` |
| Delete function/class | **High** | Removes behavior | `human_gate` |
| Change import list | Medium | May add dependency | `human_gate` |
| Add type hints | Low | Non-behavioral change | `continue` |
| Refactor for clarity | Low | No behavior change | `continue` |

## Environment Operations

| Action | Risk | Condition | Decision |
|--------|------|-----------|----------|
| Create `.venv/` | Low | If not exists | `continue` |
| Install dependency | **High** | Always | `human_gate` |
| Upgrade dependency | **High** | Always | `human_gate` |
| Remove dependency | Medium | Unused dependency | `human_gate` (summary) |
| Change Python version | **High** | Always | `human_gate` |
| Change package manager | **High** | Always | `human_gate` |
| Set environment variable | **High** | Always | `human_gate` |
| Access secret/token | **Forbidden** | Always | `forbidden` |

## Git Operations

| Action | Risk | Condition | Decision |
|--------|------|-----------|----------|
| `git add` | Low | Staging changes | `continue` |
| `git status` | Low | Inspection only | `continue` |
| `git diff` | Low | Inspection only | `continue` |
| `git log` | Low | Inspection only | `continue` |
| `git commit` | **High** | Always | `human_gate` |
| `git push` | **High** | Always | `human_gate` |
| `git merge` | **High** | Always | `human_gate` |
| `git rebase` | **High** | Always | `human_gate` |
| `git reset --hard` | **High** | Destructive | `human_gate` |
| `git branch -D` | **High** | Destructive | `human_gate` |
| Rewrite history (`filter-branch`, etc.) | **Forbidden** | Always | `forbidden` |

## Spec Operations

| Action | Risk | Condition | Decision |
|--------|------|-----------|----------|
| Edit `sdd_spec.yaml` directly | **Forbidden** | After E3 approval | `forbidden` |
| Produce `spec_diff.yaml` | Medium | Spec change needed | `human_gate` (after diff) |
| Revise `idea_brief.yaml` | Low | Before E2 | `continue` |
| Update `task_plan.yaml` | Low | Within accepted spec | `continue` |
| Mark task completed | Low | With evidence | `continue` |

## Test Operations

| Action | Risk | Condition | Decision |
|--------|------|-----------|----------|
| Run existing tests | Low | Verification phase | `continue` |
| Add new test | Low | Covers spec criterion | `continue` |
| Skip existing test | Medium | May hide regression | `human_gate` (summary) |
| Delete test | **High** | Removes verification | `human_gate` |

## Network / External Operations

| Action | Risk | Condition | Decision |
|--------|------|-----------|----------|
| HTTP request (test API) | Low | During verification | `continue` |
| Download dependency | **High** | Always | `human_gate` |
| Upload data | **High** | Always | `human_gate` |
| Access production DB | **Forbidden** | Always | `forbidden` |
| Access production service | **Forbidden** | Always | `forbidden` |

## Emergency Override

If user explicitly says "I understand the risk and want to proceed anyway":

1. Decision = `forbidden_override`
2. Record user's exact words in execution trace
3. Record the action and its risk level
4. Proceed with user's command
5. Mark as `emergency_override: true` in relevant artifact

**Usage limit**: More than 3 emergency overrides per loop indicates protocol friction. Record for Phase 5 revision.
