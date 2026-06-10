# SDD Protocol — Claude Code Harness

## Release Notes v0.3

**Date**: 2026-06-09
**Branch**: `claude/sdd-harness-dev`
**Commits**: `7497ccc` → `27f6c0a` (2 commits)
**Protocol Version**: SDD-001 v0.3
**Validation Status**: Phase 1 Complete — One end-to-end Dry Run passed

---

## What This Is

A filesystem-based governance layer that makes Claude Code follow the SDD Protocol during development. The protocol ensures:

- Structured artifacts at every phase (YAML)
- Human gates at key decision points (conversational, not file review)
- Independent agent review (separate Agent tool calls)
- Evidence collection before completion claims
- Spec diffs before product definition changes

**Not a replacement for Claude Code. A constraint layer on top.**

---

## What Works (Verified by Dry Run 001)

### Core Protocol

| Feature | Status | Evidence |
|---------|--------|----------|
| Skill recognition (`/sdd-protocol`) | ✅ | Triggered loop in fresh session |
| E1 Capture — Idea Brief | ✅ | `idea_brief.yaml` generated |
| E2 Generate Spec | ✅ | `sdd_spec.yaml` generated |
| E2R Independent Review | ✅ | 4 separate Agent calls |
| E3 Human Gate | ✅ | Conversational, no file review |
| E4 Compile Tasks | ✅ | 15 tasks mapped to spec |
| E5 Implement | ✅ | Code + tests generated |
| E6 Verify | ✅ | Independent verification, 7/7 criteria pass |
| E7 Feedback | ✅ | Evidence summary, user acceptance |
| Phase state tracking | ✅ | `current_loop.yaml` + `phase_history.yaml` |
| Deterministic transitions | ✅ | Same state → same decision |
| Append-only trace | ✅ | 13 entries, no edits |

### F1/F2 Corrections

| Correction | Status | Evidence |
|------------|--------|----------|
| Review Agent independence (F1) | ✅ | Separate Agent calls with fresh context |
| Gate modification routing (F2) | ✅ | `approved_with_modifications` routes to Spec Diff |
| Review exit criteria (new) | ✅ | Max rounds, severity thresholds defined |
| Intake question budget (new) | ✅ | 2/4/6 questions by complexity |

### Generated Code Quality (Dry Run 001)

- `reverse.py`: 21 lines, type validation, Unicode-aware docstring
- `test_reverse.py`: 9 unit tests
- Test results: 9/9 pass, 0 failures, 0 errors
- Acceptance criteria: 7/7 verified

---

## What Does Not Work / Known Limitations

### High Priority (Blocks Efficient Use)

1. **Review exit criteria untested in real session**
   - Fixed in code (v0.3), but not validated by second Dry Run
   - Could still cycle for simple features if Host misapplies criteria

2. **Skill path confusion**
   - User types `/sdd-protocol` (skill name), not `/sdd-start` (command in docs)
   - SKILL.md description field may not trigger on all intent patterns

### Medium Priority (Friction, Not Blocking)

3. **No execution_trace.yaml real-time recording**
   - Template exists but was not written during Dry Run
   - Phase history serves as proxy

4. **Review result files not created in Dry Run 001**
   - Fixed in v0.3 (new template + output requirement)
   - Not yet validated

5. **CLAUDE.md integration incomplete**
   - `.claude/SDD_PROTOCOL.md` exists but project-level `CLAUDE.md` does not reference it
   - Host may not auto-read protocol instructions

### Low Priority (Nice to Have)

6. **No active intent interception**
   - Phase 1 design: passive trigger only (`/sdd-protocol`)
   - Active trigger (auto-detect "build me...") deferred to Phase 2

7. **Single active loop only**
   - Concurrent loops not supported
   - Queue mechanism defined but untested

8. **No Python runtime for Protocol Kernel**
   - Phase 1 uses embedded markdown rules
   - Determinism depends on Host Claude's consistency

---

## How to Use

### Quick Start

```bash
# 1. Create project
mkdir ~/my-project && cd ~/my-project
git init

# 2. Copy harness files
HARNESS="/Users/wei/Documents/SDD_Protocol/.claude/worktrees/hungry-cerf-ae3e69/harness"
cp -r "$HARNESS/.sdd" ./
cp -r "$HARNESS/.claude" ./

# 3. Install skill
cp -r "$HARNESS/skill" ~/.claude/skills/sdd-protocol

# 4. Start Claude Code
claude

# 5. Trigger loop
/sdd-protocol build <your idea>
```

### Full SOP

See [SOP_NEW_SESSION_DEVELOPMENT.md](SOP_NEW_SESSION_DEVELOPMENT.md)

---

## Files Included (38 total)

```
harness/
├── .claude/
│   └── SDD_PROTOCOL.md              # Claude Code integration rules
├── .sdd/
│   ├── state/
│   │   ├── current_loop.yaml        # Loop state marker
│   │   └── phase_history.yaml       # Append-only phase transitions
│   ├── artifacts/
│   │   ├── templates/               # 9 artifact schemas
│   │   │   ├── idea_brief.yaml
│   │   │   ├── sdd_spec.yaml
│   │   │   ├── human_gate.yaml
│   │   │   ├── task_plan.yaml
│   │   │   ├── evidence_pack.yaml
│   │   │   ├── spec_diff.yaml
│   │   │   ├── execution_trace.yaml
│   │   │   └── review_result.yaml   # NEW in v0.3
│   │   └── handoffs/                # (populated during loops)
│   └── kernel/
│       ├── phases.md                # E1-E8 phase definitions + transitions
│       ├── rules.md                 # 10 core rules
│       ├── decisions.md             # 5 decision types
│       ├── human_gate_format.md     # Conversational gate template
│       ├── evidence_rules.md        # A-layer/B-layer evidence
│       └── spec_diff_rules.md       # When diff is required
├── skill/
│   ├── SKILL.md                     # Skill definition + commands
│   └── references/                  # 8 role prompts
│       ├── intake_agent.md          # + Question Budget (v0.3)
│       ├── spec_agent.md
│       ├── spec_review_agent.md     # + Exit Criteria (v0.3)
│       ├── task_compiler_agent.md
│       ├── implementation_agent.md
│       ├── verification_agent.md
│       ├── feedback_agent.md
│       └── spec_diff_agent.md
└── experiments/                     # Dry Run 001 artifacts
    ├── IDEA_BRIEF_001.md
    ├── SDD_SPEC_001.md              # v0.3
    ├── HUMAN_GATE_001.md
    ├── TASK_PLAN_001.md
    ├── EVIDENCE_PACK_001.md
    ├── PROTOCOL_FITNESS_AUDIT_001.md
    ├── CHECKPOINT_001.md
    ├── SPEC_DIFF_F1.md
    ├── SPEC_DIFF_F2.md
    ├── EXPERIMENT_LOG_001.md
    ├── FRICTION_REPORT_001.md
    └── DRY_RUN_001_MANUAL.md
```

---

## Roadmap

### Phase 1.5 (Current — In Progress)

**Goal**: Fix Dry Run 001 friction, validate with second Dry Run

| Task | Status |
|------|--------|
| Review exit criteria | ✅ Fixed, pending validation |
| Intake question budget | ✅ Fixed, pending validation |
| Review result persistence | ✅ Fixed, pending validation |
| Second Dry Run | ⏳ Pending |

### Phase 2 (Planned)

**Goal**: Active intent interception, multi-loop support, Python Kernel runtime

| Task | Status |
|------|--------|
| Auto-detect "build me..." triggers | ⏳ Planned |
| Multiple concurrent loops | ⏳ Planned |
| Protocol Kernel Python script | ⏳ Planned |
| Execution trace real-time recording | ⏳ Planned |

### Phase 3 (Planned)

**Goal**: Toy App — real project developed entirely under protocol

| Candidate | Complexity |
|-----------|------------|
| Bookmark collector with tags + search | Medium |
| Todo list with categories + due dates | Medium |
| URL shortener with REST API | High |

---

## Validation History

| Date | Event | Result |
|------|-------|--------|
| 2026-06-08 | Self-bootstrap (design harness using harness) | ✅ PASS (simulated) |
| 2026-06-08 | Protocol Fitness Audit 001 | ⚠️ PARTIAL (4 findings) |
| 2026-06-09 | Dry Run 001 (fresh session, reverse string) | ✅ PASS (with friction) |
| 2026-06-09 | Friction Report 001 | 5 items: 2 high, 2 medium, 1 low |
| 2026-06-09 | Fixes committed (exit criteria, question budget, persistence) | ✅ |
| TBD | Dry Run 002 (validate fixes) | ⏳ Pending |

---

## Branch Strategy

- **Current branch**: `claude/sdd-harness-dev`
- **Main branch**: `main` (generalized protocol, no harness code)
- **Merge plan**: None. Harness is Claude Code-specific. Future extraction possible.
- **See**: [BRANCH_STRATEGY.md](BRANCH_STRATEGY.md)

---

## Credits

- Protocol Design: SDD Protocol Experiment (self-bootstrap)
- Harness Design: Claude Code + SDD Protocol v0.3
- Dry Run 001: Fresh Claude Code session, reverse string function
- Fixes: Phase 1.5 friction response

**Protocol is the product. The harness is an instance. The loop is the validation.**
