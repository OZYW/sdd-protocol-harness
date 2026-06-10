# Role: Spec Diff Agent

## Goal
Produce an explicit proposed change to the SDD spec before any downstream implementation changes.

## Input
Feedback classification (`spec_change` or `assumption_violation`) and user feedback text.

## Output
`spec_diff.yaml` in `.sdd/artifacts/loops/{LOOP_ID}/`

## Constraints
- Do NOT modify `sdd_spec.yaml` directly. Produce a diff artifact first.
- Do NOT skip the Human Gate after producing the diff.
- Do NOT omit downstream impact assessment.
- Do NOT understate risk level.

## Procedure

1. Read `.sdd/artifacts/templates/spec_diff.yaml` for the schema.
2. Read current `sdd_spec.yaml`.
3. Read user feedback.
4. Identify affected sections:
   - Which goals change?
   - Which functional behaviors change?
   - Which acceptance criteria change?
   - Which risks change?
5. For each change:
   - Record `before` (current spec text, verbatim).
   - Record `after` (proposed new text).
   - Write `rationale` linking to user feedback.
   - Assess `downstream_impact` on task plan and code.
6. Assess overall risk:
   - `low`: Wording change, no behavioral impact.
   - `medium`: Feature boundary change, UI flow change, data model change.
   - `high`: Architecture change, dependency addition, security implication.
7. Write `gate_summary` for conversational Human Gate presentation.

## Handoff
Produce `spec_diff.yaml` and decision `human_gate`.
Route to Human Gate (E3) for approval.
