#!/bin/bash
# SDD Protocol — One-line installer
# Usage: curl -sSL https://raw.githubusercontent.com/YOURNAME/sdd-protocol/main/install.sh | bash

set -e

REPO_URL="${SDD_REPO_URL:-https://raw.githubusercontent.com/YOURNAME/sdd-protocol/main}"
SKILL_DIR="${HOME}/.claude/skills/sdd-protocol"
PROJECT_DIR="${1:-.}"

echo "=== SDD Protocol Installer ==="
echo ""

# Detect OS
OS="$(uname -s)"
case "$OS" in
  Linux*)     PLATFORM=linux;;
  Darwin*)    PLATFORM=mac;;
  CYGWIN*|MINGW*|MSYS*) PLATFORM=windows;;
  *)          PLATFORM=unknown;;
esac

echo "Detected platform: $PLATFORM"
echo ""

# Step 1: Install Skill
echo "[1/4] Installing SDD Protocol skill to $SKILL_DIR..."
mkdir -p "$SKILL_DIR/references"

# Download skill files (or copy from local if running locally)
if [ -d "$(dirname "$0")/skill" ]; then
  # Local install (from cloned repo)
  cp -r "$(dirname "$0")/skill/"* "$SKILL_DIR/"
  echo "  ✅ Installed from local directory"
else
  # Remote install (from GitHub)
  curl -fsSL "$REPO_URL/skill/SKILL.md" -o "$SKILL_DIR/SKILL.md"
  for ref in intake_agent spec_agent spec_review_agent task_compiler_agent implementation_agent verification_agent feedback_agent spec_diff_agent; do
    curl -fsSL "$REPO_URL/skill/references/${ref}.md" -o "$SKILL_DIR/references/${ref}.md"
  done
  echo "  ✅ Downloaded from $REPO_URL"
fi

# Step 2: Install Harness to Project
echo "[2/4] Installing harness to $PROJECT_DIR/.sdd/ and $PROJECT_DIR/.claude/..."
mkdir -p "$PROJECT_DIR/.sdd/state" "$PROJECT_DIR/.sdd/kernel" "$PROJECT_DIR/.sdd/artifacts/templates" "$PROJECT_DIR/.sdd/artifacts/loops" "$PROJECT_DIR/.claude"

if [ -d "$(dirname "$0")/.sdd" ]; then
  # Local install
  cp -r "$(dirname "$0")/.sdd/"* "$PROJECT_DIR/.sdd/"
  cp "$(dirname "$0")/.claude/SDD_PROTOCOL.md" "$PROJECT_DIR/.claude/"
  echo "  ✅ Installed from local directory"
else
  # Remote install
  for file in state/current_loop.yaml state/phase_history.yaml kernel/phases.md kernel/rules.md kernel/decisions.md kernel/human_gate_format.md kernel/evidence_rules.md kernel/spec_diff_rules.md kernel/risk_matrix.md artifacts/templates/idea_brief.yaml artifacts/templates/sdd_spec.yaml artifacts/templates/human_gate.yaml artifacts/templates/task_plan.yaml artifacts/templates/evidence_pack.yaml artifacts/templates/execution_trace.yaml artifacts/templates/review_result.yaml artifacts/templates/spec_diff.yaml artifacts/templates/fix_verification.yaml; do
    curl -fsSL "$REPO_URL/.sdd/$file" -o "$PROJECT_DIR/.sdd/$file" 2>/dev/null || true
  done
  curl -fsSL "$REPO_URL/.claude/SDD_PROTOCOL.md" -o "$PROJECT_DIR/.claude/SDD_PROTOCOL.md" 2>/dev/null || true
  echo "  ✅ Downloaded from $REPO_URL"
fi

# Step 3: Initialize state
echo "[3/4] Initializing state files..."
if [ ! -f "$PROJECT_DIR/.sdd/state/current_loop.yaml" ]; then
cat > "$PROJECT_DIR/.sdd/state/current_loop.yaml" << 'EOF'
# SDD Protocol — Current Loop State Marker
loop_id: null
status: idle
current_phase: null
created_at: null
updated_at: null
blocked_reason: null
EOF
fi

if [ ! -f "$PROJECT_DIR/.sdd/state/phase_history.yaml" ]; then
cat > "$PROJECT_DIR/.sdd/state/phase_history.yaml" << 'EOF'
# SDD Protocol — Phase History
schema_version: "0.1"
entries: []
EOF
fi

echo "  ✅ State initialized"

# Step 4: Verify
echo "[4/4] Verifying installation..."
ERRORS=0

for file in .sdd/kernel/phases.md .sdd/kernel/rules.md .sdd/kernel/human_gate_format.md .sdd/kernel/risk_matrix.md .claude/SDD_PROTOCOL.md; do
  if [ -f "$PROJECT_DIR/$file" ]; then
    echo "  ✅ $file"
  else
    echo "  ❌ $file MISSING"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ -d "$SKILL_DIR" ] && [ -f "$SKILL_DIR/SKILL.md" ]; then
  echo "  ✅ Skill installed"
else
  echo "  ❌ Skill NOT installed"
  ERRORS=$((ERRORS + 1))
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "=== Installation Complete ==="
  echo ""
  echo "Start using SDD Protocol:"
  echo "  cd $PROJECT_DIR"
  echo "  claude"
  echo "  /sdd-protocol build me a todo app"
  echo ""
else
  echo "=== Installation Completed with $ERRORS Errors ==="
  echo "Some files may be missing. Try reinstalling or check network connection."
  exit 1
fi
