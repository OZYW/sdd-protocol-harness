# Spec Diff F2: Prevent Spec Diff Bypass at Human Gate

## Metadata

- Diff ID: SD-F2
- Loop ID: L001
- Source Spec: SDD-001 v0.2
- Target Spec Version: 0.2
- Proposed Spec Version: 0.3
- Triggered by: Protocol Fitness Audit 001, Finding F2
- Classification: spec_change
- Risk Level: medium

## Change Summary

Prevent the Host from directly modifying an accepted spec when user feedback at Human Gate includes modifications. All modifications must route through Spec Diff Agent and a second Human Gate.

## Changes

### Change 1: rules.md — New Rule 10

**Section**: Core Rules

**Before**: Rule 9 was the last rule (or Rule 8 if F1 not yet applied)

**After**: Add Rule 10

```markdown
## Rule 10: No Direct Spec Modification After Gate Approval

Once a spec has been presented at a Human Gate (E3), it MUST NOT be directly modified by the Host or any agent based on user feedback.

**Prohibited**: Host reads Human Gate response "approved with changes" and directly edits `sdd_spec.yaml`.
**Required**: Host routes ALL modifications through Feedback Agent → Spec Diff Agent → New Human Gate.

**Procedure for gate modifications**:
1. User responds with modifications at Human Gate
2. Host records response in `human_gate.yaml` as `revised`
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
```

**Rationale**: F2 found that a user modification at Human Gate was applied directly, bypassing Spec Diff and a second gate. This creates a bypass pattern that could lead to uncontrolled drift.

**Downstream Impact**: Every gate with modifications now requires an extra loop (Diff → Gate → Apply). This is intentional — modifications should be explicit.

---

### Change 2: phases.md — E3 Gate Modification Handling

**Section**: E3_HumanGate — Exit Conditions

**Before**:
```
E3_HumanGate -> E4_CompileTasks   [condition: human_gate.decision == approved]
E3_HumanGate -> E2_GenerateSpec   [condition: human_gate.decision == revise]
E3_HumanGate -> abandoned         [condition: human_gate.decision == rejected]
```

**After**:
```
E3_HumanGate -> E4_CompileTasks   [condition: human_gate.decision == approved AND no modifications]
E3_HumanGate -> E2_Revise         [condition: human_gate.decision == approved WITH modifications]
  NOTE: E2_Revise routes to E8 Spec Diff, NOT direct spec edit
E3_HumanGate -> E2_GenerateSpec   [condition: human_gate.decision == revise (send back for redo)]
E3_HumanGate -> abandoned         [condition: human_gate.decision == rejected]
```

**Rationale**: Distinguishes between "approved as-is" and "approved with modifications." The latter must go through Spec Diff.

**Downstream Impact**: Host must detect modifications in gate response. Simple "yes" vs "yes, but change X."

---

### Change 3: SDD_PROTOCOL.md — E3 Phase Update

**Section**: E3_HumanGate

**Before**:
```markdown
### E3_HumanGate — STOP

- **Your action**: STOP all implementation. Present Human Gate.
- **Format**: Follow `.sdd/kernel/human_gate_format.md` exactly.
- **Critical**: Must be conversational. Do NOT ask user to review files.
- **Wait for**: Explicit user response (approve / revise / reject).
- **On approve**: Advance to E4.
- **On revise**: Return to E2 (clear `sdd_spec.yaml`, regenerate).
- **On reject**: Set status to `abandoned`.
```

**After**:
```markdown
### E3_HumanGate — STOP

- **Your action**: STOP all implementation. Present Human Gate.
- **Format**: Follow `.sdd/kernel/human_gate_format.md` exactly.
- **Critical**: Must be conversational. Do NOT ask user to review files.
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
```

**Rationale**: Makes the modification routing explicit. Host cannot accidentally bypass Spec Diff.

**Downstream Impact**: Host must parse gate responses for modification keywords.

---

### Change 4: feedback_agent.md — Gate Modification Classification

**Section**: Classification Rules

**Before**: (Did not have explicit gate modification handling)

**After**: Add after existing classification rules

```markdown
### Gate Modification Classification

When user responds at a Human Gate with modifications (e.g., "approved but change X", "yes, also add Y"):

1. Classify as `spec_change` — NOT `accepted`
2. Extract the specific modifications
3. Route to Spec Diff Agent (E8)
4. Do NOT route to E4 or E5

**Why gate modifications are spec changes**:
- The spec was accepted at the gate, but with conditions
- Conditions change the product definition
- All product definition changes must go through Spec Diff
```

**Rationale**: Makes it explicit that gate modifications are not acceptance — they are changes that need diff.

**Downstream Impact**: Feedback Agent must now handle gate responses in addition to post-implementation feedback.

---

### Change 5: spec_diff_rules.md — Gate Modification Trigger

**Section**: When Is a Spec Diff Required?

**Before**:
```markdown
A Spec Diff MUST be produced BEFORE any code change when the user's feedback changes ANY of the following:
[table of change types]
```

**After**:
```markdown
A Spec Diff MUST be produced BEFORE any code change when ANY of the following occurs:

| Change Type | Examples | Requires Spec Diff? |
|-------------|----------|---------------------|
| Feature scope | "Also add due dates" | Yes |
| User flow | "Make it a wizard instead of a form" | Yes |
| Acceptance criteria | "Should also work on mobile" | Yes |
| Data model | "Tasks should have categories" | Yes |
| Non-goals | "Actually, do support recurring tasks" | Yes |
| Actor or domain term | "Call them 'missions' not 'tasks'" | Yes |
| **Gate modification** | **"Approved but change X" or "Yes, also add Y"** | **Yes — MANDATORY** |
| Wording only | "Change 'title' to 'name' in UI" | No |
| Bug fix | "The checkbox doesn't toggle" | No |
| Typo | "Spelling error in button label" | No |
| Formatting | "Make the list wider" | No |
```

**Rationale**: Explicitly calls out gate modifications as requiring Spec Diff. Prevents the F2 bypass pattern.

**Downstream Impact**: None. Documentation clarification only.

---

### Change 6: human_gate_format.md — Response Handling Update

**Section**: Gate Response Handling

**Before**:
```markdown
When user responds:

- **"Approve" or "Yes" or "Looks good"** → Record `approved`, advance phase
- **"Change X" or "Also need Y" or "Not quite"** → Record `revised`, append modifications, re-enter spec phase
- **"No" or "Cancel" or "Never mind"** → Record `rejected`, abandon loop
- **Ambiguous response** → Ask clarifying question (stay in gate), do NOT guess
```

**After**:
```markdown
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
```

**Rationale**: Distinguishes "approve with mods" (needs diff) from "send back" (needs rewrite). Prevents accidental direct edits.

**Downstream Impact**: Host must parse for modification intent in approval responses.

---

## Gate Summary

**What changed**: Any user modification at a Human Gate must now route through Spec Diff Agent and a second Human Gate before the spec is modified.

**Why**: Audit F2 found that a "approved with one modification" response led to direct spec editing, bypassing the explicit diff process. This creates a bypass pattern.

**Impact**: One extra loop per gate modification (Diff → Gate → Apply). This is intentional friction to prevent drift.

**Rollback**: If friction proves excessive, Emergency Fast-Track exception allows explicit bypass with audit trail.

**Risk**: Medium. Adds user friction. But the alternative (silent drift) is worse.
