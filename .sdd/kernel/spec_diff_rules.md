# SDD Protocol — Spec Diff Rules

## When Is a Spec Diff Required?

A Spec Diff MUST be produced BEFORE any code change when the user's feedback changes ANY of the following:

| Change Type | Examples | Requires Spec Diff? |
|-------------|----------|---------------------|
| Feature scope | "Also add due dates" → Yes | Yes |
| User flow | "Make it a wizard instead of a form" → Yes | Yes |
| Acceptance criteria | "Should also work on mobile" → Yes | Yes |
| Data model | "Tasks should have categories" → Yes | Yes |
| Non-goals | "Actually, do support recurring tasks" → Yes | Yes |
| Actor or domain term | "Call them 'missions' not 'tasks'" → Yes | Yes |
| **Gate modification** | **"Approved but change X" or "Yes, also add Y"** → **MANDATORY** | **Yes** |
| Wording only | "Change 'title' to 'name' in UI" → No |
| Bug fix | "The checkbox doesn't toggle" → No |
| Typo | "Spelling error in button label" → No |
| Formatting | "Make the list wider" → No |

## Spec Diff Procedure

1. **Feedback Agent classifies** the feedback:
   - If `spec_change` → Route to E8 (Spec Diff Agent)
   - If `implementation_defect` → Route to E5 (Implementation Agent)
   - If `accepted` → Route to loop completion

2. **Spec Diff Agent produces** `spec_diff.yaml`:
   - Identify which spec sections are affected
   - Propose before/after changes
   - Include rationale linking to user feedback
   - Assess downstream impact on tasks and code
   - Mark risk level (low/medium/high)

3. **Spec Diff routes to Human Gate** (E3):
   - Present conversational summary of what changed and why
   - Include expected impact on already-implemented code
   - Include rollback path
   - Wait for user approval

4. **If approved**:
   - Apply diff to `sdd_spec.yaml`
   - Increment version number
   - Update task plan to reflect changed scope
   - Route to E5 (Implementation) for code changes

5. **If rejected**:
   - Discard diff
   - Keep original spec
   - Route back to E7 (Feedback) for new feedback

## Emergency Bypass

If user explicitly says "skip the spec diff, just change the code":

1. Decision = `forbidden`
2. Present: "This bypasses the spec-driven process. Are you sure?"
3. If user confirms: Record override in execution trace
4. Proceed with code change BUT mark as `forbidden_override`
5. Record user's exact words as evidence

This is for audit purposes. Frequent bypasses indicate protocol friction.
