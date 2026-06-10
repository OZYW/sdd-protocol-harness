# Spec Diff F1: Multi-Agent Independence Enforcement

## Metadata

- Diff ID: SD-F1
- Loop ID: L001
- Source Spec: SDD-001 v0.2
- Target Spec Version: 0.2
- Proposed Spec Version: 0.3
- Triggered by: Protocol Fitness Audit 001, Finding F1
- Classification: spec_change
- Risk Level: medium

## Change Summary

Enforce that Spec Review Agent (and other review agents) must execute as independent Agent tool calls with fresh context, never within the same context as the authoring agent.

## Changes

### Change 1: phases.md — E2_Review Sub-Phase

**Section**: E2_GenerateSpec — Phase Definition
**Field**: Exit Condition

**Before**:
```
E2_GenerateSpec -> E3_HumanGate   [auto: sdd_spec.yaml complete]
```

**After**:
```
E2_GenerateSpec -> E2_Review      [auto: sdd_spec.yaml complete]
E2_Review -> E3_HumanGate         [condition: review_result.status == pass]
E2_Review -> E2_GenerateSpec      [condition: review_result.status == needs_revision]
```

**Rationale**: Audit F1 found that Spec Review was performed by the same context as Spec Author. The review phase must be an explicit sub-phase with mandatory independence rules.

**Downstream Impact**: Host must now make a separate Agent call for review. Slightly more tool calls, but ensures independence.

---

### Change 2: phases.md — E2_Review Independence Rules

**Section**: New section under E2_Review

**Before**: (Did not exist)

**After**:
```markdown
### E2_Review — Spec Review Agent (MANDATORY INDEPENDENCE)

**Critical Rule**: This Agent call MUST be independent from E2_GenerateSpec.

- **Independence requirements**:
  1. Must be a separate `Agent` tool call, not continuation of Spec Agent
  2. Sub-agent MUST NOT have access to Spec Agent's internal reasoning
  3. Sub-agent receives ONLY: `sdd_spec.yaml` file path + `references/spec_review_agent.md`
  4. Host MUST NOT summarize or paraphrase the spec before handing off
  5. Sub-agent reads spec directly from file, not from Host's context

- **Verification of independence**:
  Host must confirm: "Did you read the spec from the file directly, or was it provided in my previous message?"
  If sub-agent says "provided in previous message" → independence violated. Restart review with fresh Agent call.
```

**Rationale**: PROTOCOL_KERNEL_v0 states "review agents must be independent from the agent whose output they review whenever practical." In Claude Code, "practical" means a separate Agent tool call. This makes the requirement explicit and verifiable.

**Downstream Impact**: Host implementation is more complex. Must track Agent call boundaries.

---

### Change 3: rules.md — New Rule 9

**Section**: Core Rules

**Before**: Rule 8 was the last rule (Single Active Loop)

**After**: Add Rule 9

```markdown
## Rule 9: Review Agent Independence

Any agent whose role includes "review" in its name MUST be invoked as a separate `Agent` tool call with no shared context from the agent whose output it reviews.

**Prohibited**: Asking the same agent instance to "now review what you just wrote."
**Required**: Fresh Agent call with role prompt + artifact file reference only.

**Affected roles**:
- Spec Review Agent (reviews Spec Agent output)
- Verification Agent (reviews Implementation Agent output)

**Exception**: None in Phase 1. Single-session execution is accepted only when the tool ecosystem does not support true isolation. When true isolation is available (e.g., multiple Claude Code sessions), it MUST be used.
```

**Rationale**: Makes the F1 finding impossible to repeat. Creates a hard rule that Host must enforce.

**Downstream Impact**: All future loops must use separate Agent calls for review phases.

---

### Change 4: SDD_PROTOCOL.md — E2 Phase Update

**Section**: E2_GenerateSpec

**Before**:
```markdown
### E2_GenerateSpec — Spec Agent + Spec Review Agent

- **Your action**: Call Agent tool with Spec Agent role, then Spec Review Agent role.
- **Input**: `idea_brief.yaml`
- **Output**: `sdd_spec.yaml`
- **Auto-advance**: When `sdd_spec.yaml` exists and review passes, advance to E3.
```

**After**:
```markdown
### E2_GenerateSpec — Spec Agent

- **Your action**: Call Agent tool with Spec Agent role.
- **Input**: `idea_brief.yaml`
- **Output**: `sdd_spec.yaml`
- **Auto-advance**: When `sdd_spec.yaml` exists, advance to E2_Review.

### E2_Review — Spec Review Agent (INDEPENDENT CALL)

- **Your action**: Call Agent tool with Spec Review Agent role in a FRESH context.
- **Critical**: The Spec Review Agent MUST read `sdd_spec.yaml` directly from file. Do NOT paste spec content into the Agent prompt.
- **Input**: File path to `sdd_spec.yaml` + `references/spec_review_agent.md`
- **Output**: Review result (pass / needs_revision)
- **On pass**: Advance to E3.
- **On needs_revision**: Return to E2_GenerateSpec with issue list.
```

**Rationale**: Separates the two phases and enforces independence through file-based handoff.

**Downstream Impact**: Host must manage two separate Agent calls for E2.

---

### Change 5: spec_review_agent.md — Independence Declaration

**Section**: Role Definition (top of file)

**Before**:
```markdown
# Role: Spec Review Agent

## Goal
Check the SDD Spec for gaps, conflicts, assumptions, and acceptance criteria quality.

## Input
`sdd_spec.yaml` from Spec Agent.
```

**After**:
```markdown
# Role: Spec Review Agent

## Independence Declaration

You are an INDEPENDENT reviewer. You were NOT the agent who wrote this spec. You have NO knowledge of the author's reasoning, assumptions, or intent beyond what is written in the file.

If the spec file is unclear, incomplete, or contradictory, you MUST flag it — even if you suspect the author had good reasons.

## Goal
Check the SDD Spec for gaps, conflicts, assumptions, and acceptance criteria quality.

## Input
`sdd_spec.yaml` from Spec Agent (read directly from file by you).
```

**Rationale**: Psychological framing for the sub-agent. Makes independence explicit in the role identity.

**Downstream Impact**: None. Role prompt only.

---

## Gate Summary

**What changed**: Spec Review must now be an independent Agent tool call. The sub-agent reads the spec directly from file, not from Host context.

**Why**: Audit F1 found that review performed by the same context as authoring may miss gaps and conflicts due to shared assumptions.

**Impact**: Slightly more Agent calls per loop, but stronger quality assurance.

**Rollback**: If independent review proves too slow or unnecessary, rule can be relaxed to "recommended" instead of "mandatory."

**Risk**: Low-Medium. Adds one tool call per loop.
