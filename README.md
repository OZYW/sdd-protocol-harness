# SDD Protocol — Claude Code Harness

[![Version](https://img.shields.io/badge/version-0.4.1-blue)](./RELEASE_NOTES_v0.4.md)
[![Status](https://img.shields.io/badge/status-real--world%20validated-green)]()

A **filesystem-based governance layer** that makes [Claude Code](https://claude.ai/code) automatically follow structured development practices.

> **Spec before code. Gate before commit. Evidence before completion.**

---

## What It Does

When you have an idea ("build me a dashboard"), the SDD Protocol harness ensures Claude Code:

1. **Captures** your intent in a structured brief
2. **Generates** an explicit spec with acceptance criteria
3. **Reviews** the spec independently for gaps
4. **Stops** at a Human Gate for your approval
5. **Compiles** the spec into implementation tasks
6. **Implements** with role-specific agents
7. **Verifies** with evidence before claiming done
8. **Collects** your feedback and routes changes correctly

No code is written without an accepted spec. No spec is changed without your explicit approval.

---

## Quick Start

### Install Skill (Once per Machine)

The skill provides the `/sdd-protocol` command interface. Install it once:

```bash
curl -sSL https://raw.githubusercontent.com/OZYW/sdd-protocol-harness/v0.4.1/install.sh | bash
```

> This installs the skill to `~/.claude/skills/sdd-protocol/`. You only need to do this once per machine, or when upgrading to a new version.

### Initialize Project Harness (Once per Project)

Run `install.sh` from within each project directory that will use SDD Protocol:

```bash
# 1. Go to your project directory
cd ~/my-new-project

# 2. Install project-level harness files
bash /path/to/install.sh

# Or if install.sh is in your PATH:
# install.sh

# 3. Start Claude Code
claude

# 4. Trigger SDD Protocol
/sdd-protocol build me a bookmark collector with tags and search
```

### Upgrade to a Newer Version

```bash
# Re-run install.sh — it updates kernel files while preserving your loop artifacts
curl -sSL https://raw.githubusercontent.com/OZYW/sdd-protocol-harness/v0.5.0/install.sh | bash
```

---

## Project Structure

```
.
├── .sdd/                          # Project-level SDD state and rules
│   ├── kernel/                    # Protocol rules (updated by install.sh)
│   │   ├── phases.md              # Phase transitions
│   │   ├── rules.md               # 12 core rules
│   │   ├── risk_matrix.md         # Action risk levels
│   │   ├── human_gate_format.md
│   │   └── ...
│   ├── artifacts/                 # Loop outputs (your work, never overwritten)
│   │   ├── templates/             # Empty artifact schemas
│   │   └── loops/
│   │       └── L001/              # One directory per loop
│   └── state/                     # Loop state markers
│       ├── current_loop.yaml
│       └── phase_history.yaml
├── .claude/
│   └── SDD_PROTOCOL.md            # Claude Code integration instructions
└── src/                           # Your actual code
```

> **Note**: `skill/` lives at `~/.claude/skills/sdd-protocol/` (user-level), not in your project directory.

---

## Commands

| Command | Description |
|---------|-------------|
| `/sdd-protocol <idea>` | Start a new SDD loop |
| `/sdd-status` | Show current loop state |
| `/sdd-continue` | Resume after a gate or blocker |
| `/sdd-abandon` | Abandon current loop |

---

## Protocol Phases

```
E1 Capture        → E2 Generate Spec → E2R Review
                                           ↓
E8 Spec Diff    ← E3 Human Gate ← (approval required)
   ↓
E4 Compile Tasks → E5 Implement → E6 Verify → E7 Feedback
                                                ↓
                                         [accept] → Done
                                         [defect] → E5
                                         [change] → E8
```

---

## Real-World Validation

This harness has been validated through:

| Test | Date | Result |
|------|------|--------|
| Self-bootstrap | 2026-06-08 | ✅ Pass |
| Dry Run 001 (todo app) | 2026-06-09 | ✅ Pass |
| Dry Run 002 (editor panel) | 2026-06-09–10 | ✅ Pass (with rescue) |

**editorpanel-sdd-project** (a real Character Panel dashboard for an editorial team):
- 21 acceptance criteria
- 36 implementation tasks
- 2 independent spec review rounds
- 1 environment boundary rescue
- 3 defect fixes during feedback
- **Outcome**: All criteria passed, loop completed

---

## Key Features

### Human Gates (Not File Reviews)

The protocol stops at gates with **conversational summaries**, not file lists:

> "I've captured your idea for a dashboard and turned it into a structured plan. Does this match what you had in mind?"
>
> **What we built:**
> - View team rankings by monthly likes
> - Manage sample inventory with version history
> - Public dashboard for visitors
>
> **Your choices:** [Approve] [Revise] [Reject]

### Independent Spec Review

Before any code is written, a separate Agent reviews the spec against a checklist:
- Are acceptance criteria testable?
- Are open questions resolved or routed to gates?
- Does the spec match the original intent?

### Risk Matrix

Every action is classified:

| Action | Risk | Decision |
|--------|------|----------|
| Edit existing file | Low | Auto-proceed |
| `git commit` | **High** | Human approval |
| Install dependency | **High** | Human approval |
| Delete file | **High** | Human approval |

### Environment Boundary Enforcement

Before implementation starts, the technology stack must be chosen and accepted:

```yaml
environment_boundary:
  status: "accepted"
  runtime_carrier: "nodejs"
  language_version: "20"
  package_manager: "npm"
  commands:
    install: "npm install"
    run: "npm run dev"
    test: "npm test"
```

No more "what language should I use?" surprises mid-implementation.

---

## Status & Roadmap

**Current**: v0.4.1 — Real-world validated

| Phase | Feature | Status |
|-------|---------|--------|
| Phase 1 | Basic loop (E1–E7) | ✅ Done |
| Phase 1.5 | Review exit criteria, question budget | ✅ Done |
| Phase 1.5b | Environment boundary + Git rules | ✅ Done |
| Phase 2 | Active intent detection | Planned |
| Phase 2 | Multi-loop support | Planned |
| Phase 2 | Execution trace real-time recording | Planned |
| Phase 3 | Python Protocol Kernel (runtime) | Planned |

---

## Contributing

This is an experimental protocol. If you use it and find friction:

1. Record the friction in your loop's artifacts
2. Open an issue on this repository describing the symptom, expected behavior, and evidence
3. Or propose a fix via pull request

---

## License

MIT — See [LICENSE](./LICENSE).

---

## Credits

- Protocol Design: SDD Protocol Experiment
- Harness Implementation: Protocol Factory (Claude Code + human steering)
- Real-World Validation: editorpanel-sdd-project
