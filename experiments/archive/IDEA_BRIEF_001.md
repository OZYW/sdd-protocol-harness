# Idea Brief 001

## Metadata

- Idea ID: IB-001
- Date: 2026-06-08
- Author: Human
- Status: draft

## Raw Intent

Build a Claude Code harness that enforces the SDD Protocol automatically. When a user asks Claude Code to do something, the harness should:

1. Capture the idea as a structured brief
2. Convert it into an SDD spec
3. Stop at defined gates for human confirmation
4. Compile accepted specs into tasks
5. Route those tasks to Claude Code Agent tools with role-specific prompts
6. Collect verification evidence before claiming completion
7. Convert feedback into spec diffs before code changes

The harness itself should be designed using the SDD Protocol — we dogfood our own methodology.

## User Constraints

- Must work within Claude Code's existing tool ecosystem (Agent, Read, Edit, Write, Bash)
- Must not require modifications to Claude Code itself
- Must keep the human surface conversational
- Must be implementable as files in a project directory
- Must not introduce external dependencies in Phase 1

## Known Preferences

- Prefer filesystem-based state over in-memory state (survives crashes, human-inspectable)
- Prefer YAML for machine-readable artifacts, Markdown for human-readable artifacts
- Prefer deterministic rules over LLM judgment for Protocol Kernel decisions

## Explicit Non-Goals

- Do not build a standalone application or web service
- Do not replace Claude Code — this is a governance layer on top
- Do not support non-Claude Code editors in Phase 1
- Do not automate human gates (gates must remain human decisions)
- Do not create a custom package manager or dependency system

## Initial Questions

1. Should the harness be a Python module, a shell script collection, or a pure file-based convention?
2. How does the harness detect that a conversation has triggered a new SDD loop vs. continuing an existing one?
3. What happens if the user explicitly asks to bypass a gate?

## Acceptance Signal (How Will I Know This Works?)

I can ask Claude Code "Build me a todo list app" and the harness causes Claude Code to:
- Generate an Idea Brief and SDD Spec before writing code
- Stop and ask me to confirm the spec (not review files, just confirm intent)
- Only write code after I approve
- Show me evidence that the code works before claiming done
- If I say "change the UI", it proposes a spec diff before changing code
