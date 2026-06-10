# SDD Protocol — Human Gate Presentation Format

## Critical Rule

The Human Gate MUST be **conversational**. It must ask the human to judge **intent, observable behavior, or explicit risk approval**.

It MUST NOT:
- Ask the human to review repository files
- Ask the human to read generated specs line by line
- Ask the human to review implementation diffs
- Present raw tool output as the default acceptance surface

File review, code review, consistency checks, and evidence review are **agent responsibilities**. The human-facing surface should summarize the decision in domain language.

---

## Presentation Template

When presenting a Human Gate, Claude Code MUST output exactly this structure:

```
--- SDD Protocol — Human Gate {GATE_ID} ---

Current state:
  {One-sentence summary of loop progress}

What needs your decision:
  {One clear question. Not "review this file" — "Does this direction match your intent?"}

What we built:
  {2-3 bullet points summarizing the spec in user language. No technical jargon.}

What it will do:
  {2-3 bullet points on expected behavior when implemented}

Environment boundary (MANDATORY for E3 Gate):
  {If environment_boundary.status != "accepted", present this section}
  Technology stack: {Not selected / Proposed: X}
  Runtime: {e.g. Python 3.12, Node.js 20}
  Framework: {e.g. Django, FastAPI, Express}
  Database: {e.g. SQLite, PostgreSQL}
  Package manager: {e.g. uv, npm}
  How to run tests: {command}
  How to run the app: {command}

Recommended option:
  {Approve / Revise / Reject — with brief why}

If you approve:
  {What happens next — in one sentence}

If you want changes:
  {What happens — "I'll generate a revised spec for your approval"}

If you reject:
  {What happens — "Loop ends, no code changes made"}

Your choices:
  [Approve] [Revise — tell me what to change] [Reject]

(You do not need to review files. Just tell me if this matches what you want.)
---
```

---

## Examples

### Good (Conversational)

> **Current state:** I've captured your idea for a todo list app and turned it into a structured plan.
>
> **What needs your decision:** Does this plan match what you had in mind?
>
> **What we built:**
> - Add tasks with titles and due dates
> - Mark tasks complete with a checkbox
> - View all tasks in a simple list
>
> **What it will do:**
> - You'll type a task name and pick a date
> - Click a box to mark it done
> - See everything in one scrollable list
>
> **Recommended option:** Approve — this is the smallest useful version.
>
> **If you approve:** I'll break this into implementation tasks and start coding.
>
> **Your choices:** [Approve] [Revise — tell me what to change] [Reject]

### Bad (File Review)

> Please review `sdd_spec.yaml` and let me know if the functional behavior section is correct.
> The spec defines actors, domain terms, and acceptance criteria. Please check the following:
> - Actor table on line 45
> - Acceptance criteria A-003
> - Risk assessment section

---

## Gate Response Handling

When user responds:

- **"Approve" or "Yes" or "Looks good"** (no modifications mentioned):
  → Record `approved`, advance phase

- **"Approve" WITH modifications** (e.g., "Yes, but change X", "Approved, also add Y"):
  → Record `revised_with_modifications`
  → Extract modifications
  → Route to Spec Diff Agent (E8) — do NOT advance to E4
  → After spec diff produced, return to E3 for second approval

- **"Change X" or "Also need Y" or "Not quite"** (without explicit approve/reject):
  → Record `revised`
  → Return to E2 (clear spec, regenerate)

- **"No" or "Cancel" or "Never mind"** → Record `rejected`, abandon loop
- **Ambiguous response** → Ask clarifying question (stay in gate), do NOT guess

---

## Environment Boundary at E3 (Rule 11 Enforcement)

The E3 Human Gate MUST include an **environment boundary decision** before approval.

### Procedure

1. Before presenting E3 Gate, read `sdd_spec.yaml` `environment_boundary` section.
2. If `status == "accepted"`:
   - Include environment summary in gate presentation (runtime, language, framework)
   - Proceed with normal approval flow
3. If `status == "not_selected"` or `status == "proposed"`:
   - Present environment boundary as a **secondary decision** within the same gate
   - Ask user to confirm or select: runtime carrier, language version, framework, database, package manager
   - Record user selections in `human_gate.yaml` under `environment_boundary_decision`
   - Update `sdd_spec.yaml` `environment_boundary` to `accepted` with selected values
   - Only then record gate as `approved`

### Why

- Prevents loop from advancing to E5 with undefined technology stack
- Ensures Implementation Agent knows which language, framework, and tools to use
- Avoids mid-implementation technology debates that derail task scope

### Example (Environment Boundary Section in Gate)

> **Technology stack:** Not yet selected — needs your decision
>
> I've planned the features, but we haven't chosen the implementation stack.
> Here's what I recommend:
> - **Backend:** Python 3.12 + FastAPI
> - **Frontend:** Server-side rendering with Jinja2
> - **Database:** SQLite for now (easy to migrate to PostgreSQL later)
> - **Package manager:** uv
> - **Run:** `uv run python main.py`
> - **Test:** `uv run pytest`
>
> Does this stack work for you? Or do you prefer something else?
>
> [Python + FastAPI looks good] [I want Node.js instead] [I'll decide later — block implementation]

### If user says "I'll decide later"

- Decision = `approved_with_conditions`
- Condition = "environment_boundary deferred to pre-implementation gate"
- Set `environment_boundary.status = "deferred"`
- Advance to E4 (Task Compiler)
- E4→E5 transition will block until environment boundary is accepted (see phases.md Rule 2)
