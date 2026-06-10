# SOP: New Session Development with SDD Protocol

## Purpose

Standard operating procedure for starting a new Claude Code session that uses the SDD Protocol harness for real development. This SOP is the single source of truth for how protocol-based development flows between the **Protocol Factory** (current session, protocol iteration) and the **Protocol Battlefield** (new session, real usage).

## Prerequisites

- Branch `claude/sdd-harness-dev` has the latest harness
- You know the path to the harness files in the worktree

## Phase 1: Environment Setup (New Session)

### Option A: One-line Install (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/YOURNAME/sdd-protocol/main/install.sh | bash
```

This installs both the skill (to `~/.claude/skills/sdd-protocol/`) and the harness files (to current directory).

### Option B: Manual Install from Cloned Repo

```bash
# 1. Clone the repo
git clone https://github.com/YOURNAME/sdd-protocol.git
cd sdd-protocol

# 2. Run install script
bash install.sh /path/to/your-project

# 3. Or copy manually
HARNESS="/path/to/sdd-protocol/harness"
cp -r "$HARNESS/.sdd" /path/to/your-project/
cp -r "$HARNESS/.claude" /path/to/your-project/
cp -r "$HARNESS/skill" ~/.claude/skills/sdd-protocol
```

### Step 1.1: Verify Installation

```bash
cd /path/to/your-project
cat .sdd/state/current_loop.yaml
cat .claude/SDD_PROTOCOL.md
```

### Step 1.2: Version Check (Critical)

**Why**: Skill and project-level files must be the same version.

```bash
# Check skill version
grep -q "Environment Boundary at E3" ~/.claude/skills/sdd-protocol/references/spec_review_agent.md 2>/dev/null \
  && echo "✅ Skill: latest" || echo "⚠️ Skill may be outdated"

# Check project version
grep -q "Environment Boundary at E3" .sdd/kernel/human_gate_format.md 2>/dev/null \
  && echo "✅ Project: latest" || echo "⚠️ Project files may be outdated"
```

**If outdated**: Re-run `install.sh` or `git pull` the repo.

### Step 1.3: Update Existing Installation

```bash
# From your project directory
curl -sSL https://raw.githubusercontent.com/YOURNAME/sdd-protocol/main/install.sh | bash
```

This safely updates kernel files while preserving your loop artifacts.

### Step 1.4: Start Claude Code

```bash
claude
```

## Phase 2: SDD Loop Execution (New Session)

### Step 2.1: Trigger Loop

```
/sdd-protocol <your natural language idea>
```

Example:
```
/sdd-protocol build a bookmark collector with tags and search
```

### Step 2.2: Observe and Interact

Claude will execute phases automatically. You only need to respond at:
- **E3 Human Gate**: Approve, Revise, or Reject
- **E7 Feedback**: Accept, Report Bug, or Request Change

Do not review files. Confirm intent, behavior, or risk only.

### Step 2.3: Complete or Abandon

- **Accept** → Loop completes, `status: completed`
- **Report Bug** → Routes to E5 (Implementation fix)
- **Request Change** → Routes to E8 (Spec Diff) → E3 (New Gate)
- **Abandon** → `/sdd-abandon` or manual signal

## Phase 3: Problem Escalation (New Session → Protocol Factory)

### When to Escalate

Escalate to the Protocol Factory (current session) when:

| Symptom | Severity | Example |
|---------|----------|---------|
| Review cycles beyond max rounds | High | 3+ reviews for simple feature |
| Agent ignores role constraints | High | Implementation Agent changes spec directly |
| Gate is not conversational | High | Claude asks "review this file" |
| Phase skipped without reason | High | E3 gate bypassed |
| Review not independent | Medium | Same context reviews itself |
| Evidence missing before completion | Medium | Claims done with no test output |
| Intake asks too many questions | Medium | Simple idea gets 4+ questions |
| Minor formatting / presentation noise | Low | Skill timing prints in gate output |

### How to Escalate

1. **In New Session**: Stop. Do not work around the problem.
2. **Copy the problem evidence**:
   ```bash
   # Copy relevant artifacts
   cp .sdd/artifacts/loops/LXXX/sdd_spec.yaml /tmp/problem_spec.yaml
   cp .sdd/state/phase_history.yaml /tmp/problem_history.yaml
   # Or screenshot the conversation
   ```
3. **Switch to Protocol Factory session** (this session)
4. **Report using this template**:
   ```
   ## Bug Report
   - Phase: E2, E3, E5, etc.
   - Symptom: What went wrong
   - Expected: What should have happened per protocol
   - Actual: What actually happened
   - Evidence: File paths or conversation excerpts
   - Severity: high / medium / low
   ```

## Phase 4: Protocol Fix (Protocol Factory)

### Step 4.1: Diagnose

1. Read the relevant role prompt (`references/{role}_agent.md`)
2. Read the relevant kernel rule (`.sdd/kernel/rules.md` or `phases.md`)
3. Identify root cause: is it prompt ambiguity, missing rule, or protocol gap?

### Step 4.2: Fix

1. Edit the relevant file(s)
2. Update version number if spec changes
3. Write a Spec Diff if the fix changes product definition

### Step 4.3: Commit

```bash
git add harness/
git commit -m "fix: <brief description>

<what was wrong> → <what was fixed>
Triggered by: <reference to battlefield report>"
```

### Step 4.4: Sync to Battlefield

```bash
# In New Session (from your project directory)
curl -sSL https://raw.githubusercontent.com/YOURNAME/sdd-protocol/main/install.sh | bash

# Or if you cloned the repo locally
bash /path/to/sdd-protocol/install.sh
```

**After sync, run version check (Step 1.2) to confirm match.**

## Phase 5: Re-test (New Session)

1. Restart Claude Code in project directory
2. Re-trigger `/sdd-protocol` with same or similar idea
3. Verify the fix worked
4. If not fixed → repeat Phase 3-5

## SOP Version

- Version: 1.1
- Protocol Version: SDD-001 v0.4.1
- Date: 2026-06-10
- Distribution: GitHub (github.com/YOURNAME/sdd-protocol)
- Previous: Local file copy (v1.0)
