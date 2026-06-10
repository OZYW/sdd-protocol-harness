# SDD Protocol — Claude Code Harness

## Release Notes v0.4.1

**Date**: 2026-06-10
**Branch**: `claude/sdd-harness-dev`
**Previous**: v0.4
**Protocol Version**: SDD-001 v0.4.1
**Validation Status**: ✅ Real-world validated (editorpanel-sdd-project, 21/21 criteria, 36 tasks)

---

## What's New in v0.4

### B-1: Lightweight Environment & Git Rules

Addresses the gap identified in the Execution & Feedback Protocol review. No new agents or phases added; rules and constraints expanded.

#### 1. Environment Boundary Enforcement (Rule 11)

**Location**: `rules.md` Rule 11, `sdd_spec.yaml` template, `implementation_agent.md`

**What changed**:
- `sdd_spec.yaml` template: `environment_boundary` expanded from 5 fields to 13 fields
  - Added: `status`, `language_version`, `dependency_file`, `virtual_env`, `virtual_env_required`
  - Added: `commands.install`, `commands.run`, `commands.test`, `commands.build`, `commands.lint`
- `rules.md` Rule 11: Environment MUST be defined (`status: accepted`) before implementation
- `implementation_agent.md`: Constraints added — no global pip, use `.venv/` only, respect declared dependencies

**Why**: Prevents Implementation Agent from polluting global Python or introducing undeclared dependencies.

#### 2. Git Operation Rules (Rule 12)

**Location**: `rules.md` Rule 12

**What changed**:
- 10 Git operations classified by risk level
- High-risk (commit, push, merge, rebase, reset --hard, branch -D): require `human_gate`
- Low-risk (add, status, diff, log): may proceed automatically
- Git hygiene: commit messages must reference spec clause or task ID

**Why**: Prevents arbitrary commits/pushes without human approval; maintains Git as audit trail.

#### 3. Risk Matrix (New File)

**Location**: `kernel/risk_matrix.md`

**What changed**:
- 50+ development actions mapped to risk levels and decisions
- Categories: File Operations, Code Operations, Environment, Git, Spec, Test, Network
- Emergency override procedure defined (max 3 per loop before friction flag)

**Why**: Single source of truth for "can I do this automatically or do I need to stop?"

#### 4. Critical Constraints Expanded

**Location**: `.claude/SDD_PROTOCOL.md`

**Added**:
- Constraint 7: Environment boundary must be defined
- Constraint 8: Git operations need approval
- Constraint 9: Risk matrix governs all actions

---

## Files Changed

| File | Change |
|------|--------|
| `.sdd/artifacts/templates/sdd_spec.yaml` | Environment Boundary expanded (13 fields) |
| `.sdd/kernel/rules.md` | Rule 11 (Environment), Rule 12 (Git) added |
| `.sdd/kernel/risk_matrix.md` | **NEW** — 50+ action risk mappings |
| `.claude/SDD_PROTOCOL.md` | Constraints 7-9 added; v0.4.1: Gate enforcement, trace rule, risk check, fix verification |
| `skill/references/implementation_agent.md` | Environment constraints added |
| `.sdd/kernel/human_gate_format.md` | v0.4.1: Environment Boundary at E3 chapter |
| `.sdd/kernel/evidence_rules.md` | v0.4.1: human_acceptance rule, fix verification procedure |
| `.sdd/artifacts/templates/fix_verification.yaml` | **NEW** — Fix verification artifact template |
| `install.sh` | **NEW** — One-line installer |
| `README.md` | **NEW** — Complete project documentation |
| `LICENSE` | **NEW** — MIT License |
| `.gitignore` | **NEW** — Runtime state exclusion |
| `SOP_NEW_SESSION_DEVELOPMENT.md` | v0.4.1: install.sh based workflow |
| `experiments/` | Cleaned: archive/ created, PFA-002 kept as public evidence |

---

## What's New in v0.4.1 (Real-World Validation Release)

### Hotfix: E4→E5 Environment Boundary Gate

**Location**: `phases.md`, `SDD_PROTOCOL.md`

**What changed**:
- E4→E5 transition now requires BOTH `task_plan.yaml` exists AND `environment_boundary.status == "accepted"`
- If environment boundary is not accepted, loop stops at E4 and presents Environment Boundary Gate
- Added "Phase Transition Trace Rule" to SDD_PROTOCOL.md requiring auto-append to phase_history.yaml after every transition

**Why**: Prevents loop from advancing to implementation with undefined technology stack.

### Fix: Human Gate Format Enforcement

**Location**: `SDD_PROTOCOL.md`, `human_gate_format.md`

**What changed**:
- E3 section: Host MUST read template before presenting; MUST include all required sections
- E7 section: Added risk matrix check for post-loop actions; human_acceptance criteria handling
- human_gate_format.md: Added mandatory "Environment Boundary at E3" chapter with procedure and examples

**Why**: Prevents gate deviation that confused user with推进式提问 instead of clear [Approve]/[Revise]/[Reject] choices.

### Fix: Evidence Rules for human_acceptance and Fix Verification

**Location**: `evidence_rules.md`, new `fix_verification.yaml` template

**What changed**:
- `human_acceptance` criteria MUST NOT be marked as verified by automated verification — only user explicit confirmation qualifies
- Added "Fix Verification" procedure for loops returning from E7 to E5
- New artifact template: `fix_verification.yaml`

### Distribution: GitHub-Ready

**Location**: New files `install.sh`, `README.md`, `LICENSE`, `.gitignore`

**What changed**:
- One-line install script supporting both local and remote (GitHub) install
- Comprehensive README with quick start, features, validation history
- MIT License
- `.gitignore` excluding runtime state and artifacts
- `experiments/` cleaned: old files moved to `archive/`, kept PFA-002 and Friction Report as public evidence
- SOP updated from file-copy to install-script based workflow

**Why**: Enables stable versioned distribution. Users `install.sh` instead of manual `cp`, preventing version skew.

---

## What Still Works (from v0.3)

All v0.3 features remain functional:
- Skill recognition, phase execution, human gates
- Independent review agents (F1 fix)
- Gate diff routing (F2 fix)
- Review exit criteria, intake question budget, review persistence

---

## Known Limitations

| # | Limitation | Status |
|---|-----------|--------|
| 1 | Review exit criteria | ✅ Tested in editorpanel-sdd-project (2 rounds, pass) |
| 2 | Skill path confusion (`/sdd-protocol` vs `/sdd-start`) | Documented, accepted |
| 3 | No execution_trace.yaml real-time recording | Phase 2 |
| 4 | Single active loop only | Phase 2 |
| 5 | No active intent interception | Phase 2 |
| 6 | **E4→E5 transition lacked environment_boundary check** | **Fixed in harness v0.4.1-hotfix** |
| 7 | **Human Gate presentation not enforced by template** | **Fixed in harness v0.4.1-hotfix** |

---

## Validation History

| Date | Event | Result |
|------|-------|--------|
| 2026-06-08 | Self-bootstrap | Pass |
| 2026-06-08 | Protocol Fitness Audit 001 | Partial |
| 2026-06-09 | Dry Run 001 | Pass (with friction) |
| 2026-06-09 | Friction Report 001 | 5 items documented |
| 2026-06-09 | Fixes v0.3 (exit criteria, question budget, persistence) | Committed |
| 2026-06-09 | **B-1 Environment & Git Rules v0.4** | **Implemented** |
| 2026-06-09–10 | **Dry Run 002: editorpanel-sdd-project** | **✅ Pass** (21/21 criteria, 36 tasks, 3 defect fixes, 1 rescue) |
| 2026-06-09 | Hotfix: E4→E5 environment_boundary gate + human_gate_format enforcement | Applied to harness (bb2957d) |
| 2026-06-10 | **Protocol Fitness Audit 002** | **Partial** (8 findings, 6 proposed fixes applied) |
| 2026-06-10 | **v0.4.1 Release** | **GitHub-ready** (install.sh, README, LICENSE, .gitignore) |

---

## Next Steps

1. **Publish to GitHub**: Create independent repo, push v0.4.1
2. **Community testing**: Invite users to try `install.sh` and report friction
3. **Phase 2 planning**: Active intent detection, multi-loop support, Python Protocol Kernel
4. **Long-term**: Package manager integration (npm/pip install sdd-protocol)

---

## Branch Strategy

Unchanged from v0.3. See `BRANCH_STRATEGY.md`.

---

## Credits

- Protocol Design: SDD Protocol Experiment
- B-1 Design: User requirement for Execution & Feedback Protocol completeness
- Implementation: Protocol Factory (current session)
