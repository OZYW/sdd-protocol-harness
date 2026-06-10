# Protocol Fitness Audit 002

## Metadata

- Audit ID: PFA-002
- Loop ID: L001 (editorpanel-sdd-project)
- Date: 2026-06-10
- Auditor: Protocol Factory (current session)
- Protocol Version: SDD-001 v0.4 + hotfix bb2957d
- Source: Real-world development loop with runtime verification

---

## Execution Trace Summary

| Step | Phase | Agent Role | Decision | Artifact | Duration |
|------|-------|------------|----------|----------|----------|
| 1 | E1_Capture | Intake Agent | continue | `idea_brief.yaml` | ~5 min |
| 2 | E2_GenerateSpec | Spec Agent | continue | `sdd_spec.yaml` v0.1 | ~15 min |
| 3 | E2_Review R1 | Spec Review Agent | needs_revision | `review_result_1.yaml` | ~15 min |
| 4 | E2_GenerateSpec (revise) | Spec Agent | continue | `sdd_spec.yaml` v0.2 | ~15 min |
| 5 | E2_Review R2 | Spec Review Agent | pass | `review_result_2.yaml` | ~15 min |
| 6 | E3_HumanGate | Host | human_gate | `human_gate_e3.yaml` | — |
| 7 | E4_CompileTasks | Task Compiler Agent | continue | `task_plan.yaml` | ~10 min |
| 8 | **RESCUE** | Host | blocked | `human_gate_e3b_env_boundary.yaml` | — |
| 9 | E5_Implement | Implementation Agent | continue | 36 tasks completed | ~24 hours |
| 10 | E6_Verify | Verification Agent | continue | `evidence_pack.yaml` | ~30 min |
| 11 | E7_Feedback | Host | human_gate | E7 gate presentation | — |
| 12 | E5_Implement (fix) | Implementation Agent | continue | D-002/D-003/D-004 fixed | ~30 min |
| 13 | E7_Feedback (re-verify) | Host | human_gate | Updated evidence_pack | ~15 min |
| 14 | **COMPLETED** | Host | continue | Loop marked completed | — |

**Total duration**: ~2 days (with overnight implementation)
**Total tokens**: Estimated 200k+ (36 implementation tasks + verification)
**Outcome**: 21/21 criteria passed, 3/4 defects fixed, 1 known issue (D-001)

---

## Audit Findings

### Finding F1: E3 Human Gate Presentation Violated Format

**Severity**: High
**Category**: Human Gate Format Violation

**Description**: The E3 Human Gate was presented as a推进式提问 ("🚀 下一步 Spec 和 Task Plan 已就绪。你接下来可以：进入实现 / 先选技术栈 / 查看详细任务。你想如何进行？") instead of the mandatory 7-section conversational format.

**Protocol Rule Violated**: `human_gate_format.md` — "Claude Code MUST output exactly this structure" with 7 required sections.

**Impact**: User was not given clear [Approve] [Revise] [Reject] choices. Technology stack decision was buried in alternatives, not presented as mandatory. Environment boundary status was not disclosed.

**Root Cause**: `SDD_PROTOCOL.md` E3 section references `human_gate_format.md` but does not enforce it. The Host (Claude Code) used its own judgment instead of following the template.

**Mitigation**: Add enforcement rule to `SDD_PROTOCOL.md` E3 section: "If gate presentation deviates from template, STOP and re-present using exact format."

**Status**: Discovered during loop, fixed in `human_gate_e3.yaml` protocol_audit section. Harness hotfix adds Environment Boundary enforcement to gate format.

---

### Finding F2: E4→E5 Transition Missing Environment Boundary Check

**Severity**: High
**Category**: Phase Transition Rule Violation

**Description**: Loop advanced from E4 to E5 when `environment_boundary.status == "not_selected"`. All environment fields (runtime_carrier, language_version, package_manager, commands) were empty.

**Protocol Rule Violated**: Rule 11 — "Environment Boundary Must Be Defined Before Implementation."

**Impact**: Implementation Agent was allowed to write code without knowing the technology stack. Would have resulted in implementation errors or arbitrary technology choices.

**Root Cause**: `phases.md` Rule 2 E4→E5 transition only checked `task_plan.yaml exists`, not `environment_boundary.status == "accepted"`.

**Mitigation**: Fixed in hotfix bb2957d. E4→E5 now requires both task plan AND accepted environment boundary.

**Status**: **FIXED** in harness. Experiment project loop was rescued by rolling back to E4.

---

### Finding F3: E7 Gate Understated npm install Risk

**Severity**: Medium
**Category**: Risk Matrix Application

**Description**: E7 Gate listed "npm install — 安装依赖后才能运行和测试" as a routine next step, without mentioning it is a **High Risk** action per `risk_matrix.md`.

**Protocol Rule Violated**: Constraint 9 — "Risk matrix governs all actions."

**Impact**: User may execute npm install without understanding it modifies project state and downloads external code. No human approval was requested.

**Root Cause**: E7 Gate presentation did not reference `risk_matrix.md` for the npm install action.

**Mitigation**: Add to `SDD_PROTOCOL.md` E7 section: "Before recommending any post-loop action, check risk_matrix.md. High Risk actions must be flagged explicitly."

**Status**: Proposed fix. Not yet implemented in harness.

---

### Finding F4: E7 Gate Missing Rollback Path and Consequence

**Severity**: Medium
**Category**: Human Gate Format Violation

**Description**: E7 Feedback Gate did not include "Rollback path" or "Consequence of no decision" sections, which are required by `human_gate_format.md`.

**Protocol Rule Violated**: `human_gate_format.md` template requires 7 sections including rollback and consequence.

**Impact**: User did not know what happens if they don't respond, or how to reverse their choice.

**Root Cause**: Same as F1 — gate format not enforced.

**Mitigation**: Same as F1.

**Status**: Proposed fix.

---

### Finding F5: A-020 Human Acceptance Permitted Skip

**Severity**: Medium
**Category**: Evidence Rule

**Description**: A-020 (visual style) requires `human_acceptance` verification method. At first E7 presentation, A-020 was "需人工确认" but [接受] option was offered without warning that visual verification would be skipped.

**Protocol Rule Violated**: Rule 4 — "Evidence before completion." `evidence_pack.yaml` claimed `all_criteria_met: true` while A-020 was pending human acceptance.

**Impact**: Loop could have been marked complete without visual style verification.

**Root Cause**: Verification Agent set `verified: true` for A-020 based on code structure, not actual visual inspection. The `human_acceptance` method was not treated differently from `test` method.

**Mitigation**: Add to `evidence_rules.md`: "`human_acceptance` criteria MUST NOT be marked as met by automated verification. They require explicit user confirmation at a Human Gate."

**Status**: Proposed fix. Actual loop runtime verification was performed later (npm install + screenshot), so final state is compliant.

---

### Finding F6: Phase History Initially Empty

**Severity**: Low
**Category**: Evidence Rule

**Description**: When loop started, `phase_history.yaml` contained only template comments with empty `entries: []`. All transitions were lost until reconstructed during rescue.

**Protocol Rule Violated**: Rule 6 — "Append-only trace. Every phase transition appends a trace entry."

**Impact**: No real-time audit trail for the first 6 phases of the loop.

**Root Cause**: Template file was never written to during loop execution. Host did not append entries.

**Mitigation**: Add to `SDD_PROTOCOL.md`: "After EVERY phase transition, Host MUST append to `.sdd/state/phase_history.yaml`." Consider automating via a Host helper function.

**Status**: Proposed fix. Phase history was reconstructed during rescue and is now complete.

---

### Finding F7: SOP Copy-Based Sync is Error-Prone

**Severity**: Medium
**Category**: Distribution / Version Management

**Description**: SOP instructs `cp -r "$HARNESS/.sdd" ./` which copies ALL files, but:
1. Cannot distinguish between "core protocol files" and "loop-specific artifacts"
2. Overwrites loop-specific state if re-run
3. No mechanism for incremental updates when harness evolves

**Protocol Rule Referenced**: SOP_NEW_SESSION_DEVELOPMENT.md Step 1.2

**Impact**: Version skew between Factory and Battlefield. Experiment project had old `phases.md` and `human_gate_format.md` because it was copied before hotfix.

**Root Cause**: File-based distribution model lacks version metadata and update mechanism.

**Mitigation**: 
- **Immediate**: Add `install.sh` that copies only kernel files, preserving artifacts/
- **Long-term**: Git submodule or package manager-based distribution

**Status**: Proposed fix. Will be addressed in GitHub repo preparation.

---

### Finding F8: Defect Fix Verification Not Recorded Separately

**Severity**: Low
**Category**: Evidence Rule

**Description**: When D-002/D-003/D-004 were fixed and loop returned to E7, the evidence pack was updated but no separate "fix verification" artifact was created. The distinction between initial verification and re-verification is unclear.

**Protocol Rule Referenced**: Rule 4 — "Evidence must be collected on the fix."

**Impact**: Audit trail does not clearly show that fixes were verified independently.

**Mitigation**: Add to `SDD_PROTOCOL.md`: "When loop returns from E7 to E5 for defect fix, create a `fix_verification.yaml` artifact documenting what was fixed, how, and that re-verification passed."

**Status**: Proposed fix.

---

## Compliance Summary

| Protocol Area | Status | Findings |
|---------------|--------|----------|
| Idea-to-Spec Protocol | PASS | Intent preserved, assumptions clarified at E1 gate |
| Spec-to-Production Protocol | PASS | Tasks mapped, spec clauses traced |
| Spec Review | PASS | 2 rounds, exit criteria worked, review results persisted |
| **Human Gate Format** | **FAIL** | F1, F4 — Gate deviated from template, missing sections |
| **Environment Boundary** | **FAIL** | F2 — Auto-advanced without accepted env boundary |
| **Risk Matrix Application** | **PARTIAL** | F3 — npm install not flagged as High Risk |
| Execution & Feedback | PASS | Feedback correctly routed to E5 for defect fix |
| Evidence Collection | PARTIAL | F5, F6, F8 — human_acceptance not gated, trace not real-time, fix verification not separated |
| Multi-Agent Rules | PASS | Review was independent (separate Agent calls) |
| Git Rules | PASS | No unauthorized commits |
| **Distribution** | **FAIL** | F7 — Copy-based sync caused version skew |

## Overall Verdict

**PARTIAL — with documented rescues**

The protocol preserved the intended collaboration model with significant real-world validation, but with the following critical issues:

1. **Human Gate format is not enforced by the Host.** The template exists but Host routinely deviates. Need structural enforcement (e.g., Host MUST read template before presenting any gate).
2. **E4→E5 transition had a logic hole.** Fixed by hotfix, but reveals that phase rules need automated validation (not just human-readable docs).
3. **Distribution model causes version skew.** Copy-based SOP is insufficient for evolving protocol. Need install script or package mechanism.
4. **Evidence handling for human_acceptance and fix-verification needs refinement.**

## Recommendation

This execution trace may proceed to **GitHub release v0.4.1** with the following fixes applied:

- [x] F2 fixed (hotfix bb2957d)
- [ ] F1, F3, F4 — Add gate format enforcement to SDD_PROTOCOL.md
- [ ] F5 — Update evidence_rules.md for human_acceptance
- [ ] F6 — Add phase_history auto-append instruction to SDD_PROTOCOL.md
- [ ] F7 — Replace cp-based SOP with install.sh
- [ ] F8 — Add fix_verification.yaml template

After fixes, label:

> **real-world validated — editorpanel-sdd-project — v0.4.1**

---

## Post-Audit Actions

| Action | File | Status |
|--------|------|--------|
| Hotfix E4→E5 env boundary check | `phases.md` | ✅ Committed bb2957d |
| Hotfix gate format env boundary section | `human_gate_format.md` | ✅ Committed bb2957d |
| Add gate format enforcement | `SDD_PROTOCOL.md` | 🔄 Pending |
| Add risk matrix check to E7 | `SDD_PROTOCOL.md` | 🔄 Pending |
| Add human_acceptance rule | `evidence_rules.md` | 🔄 Pending |
| Add phase_history auto-append | `SDD_PROTOCOL.md` | 🔄 Pending |
| Create install.sh | New file | 🔄 Pending |
| Create fix_verification template | New file | 🔄 Pending |
| Clean experiments/ for GitHub | Directory reorg | 🔄 Pending |
| Write README.md | New file | 🔄 Pending |
