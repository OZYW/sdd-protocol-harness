# Human Gate 001

## Metadata

- Gate ID: HG-001
- Loop ID: L001
- Phase: E3_HumanGate
- Source Spec: SDD-001
- Date: 2026-06-08

## Current State

- Idea Brief (IB-001) captured user intent
- SDD Spec (SDD-001) converted intent into structured product definition
- Spec includes 10 functional behaviors, 10 acceptance criteria, state model, risks

## Decision Needed

Approve, revise, or abandon the SDD Spec for the Claude Code SDD Harness.

## User Response

**Approved with one modification.**

## Approved Options

1. **Architecture**: Accept layered hybrid (Skill + Files + CLAUDE.md)
2. **Skill installation level**: User-level (`~/.claude/skills/`)
3. **Phase 1 scope**: Minimal viable — passive trigger + filesystem state

## Modification Requested

User explicitly chose **A (passive trigger)** for Phase 1.

This means:
- Skill does NOT auto-trigger on "build me an app" in Phase 1
- User must explicitly invoke SDD loop via `/sdd-start`, `/sdd-status`, or similar
- Skill provides command interface and role prompts, not intent interception
- Active intent interception is deferred to Phase 2

## Expected Impact

- Phase 1 scope is smaller and more achievable
- Core value (structured artifacts, human gates, evidence collection) is preserved
- User experience requires explicit opt-in per loop (less friction in exploration)
- Skill template can be designed to support both passive and active modes for future upgrade

## Rollback Path

If passive trigger proves insufficient, Phase 2 can extend skill description to include active trigger patterns without changing file state layer.

## Consequence of No Decision

Experiment remains at spec stage. No implementation begins.

## Result

**APPROVED** — Proceed to Task Plan.
