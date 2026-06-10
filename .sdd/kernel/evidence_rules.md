# SDD Protocol — Evidence Rules

## Two-Layer Evidence Model

### A-Layer (Promotable)

Evidence that MAY promote completion status, roadmap advancement, or deployment decisions.

| Type | Description | Example | Stored As |
|------|-------------|---------|-----------|
| `file` | Existence and content of a generated file | `src/todo.py` exists and contains `class Todo` | File path reference |
| `git_diff` | Changes recorded in Git | Diff shows expected files modified | Command output or file |
| `command_output` | Output of a shell command | `python -m pytest` output | Command + output text |
| `test` | Automated test results | All 5 tests pass | Test runner output |
| `screenshot` | Visual evidence of UI | Screenshot shows todo list rendered | Image file path |
| `log` | Runtime log output | Server starts without errors | Log file path |
| `runtime_state` | Live application state | API responds with 200 | Curl output or similar |

### B-Layer (Non-Promotable)

Evidence that may inform decisions but MAY NOT alone promote status.

| Type | Description | Example |
|------|-------------|---------|
| `doc_ref` | Official documentation citation | "React docs say useState accepts initial value" |
| `release_note` | Dependency release notes | "v2.0 introduces breaking change to API" |
| `issue_ref` | GitHub issue or Stack Overflow | "Issue #123 describes same error" |
| `external_explanation` | Blog post, tutorial, or article | "MDN explains Promise.all behavior" |

## Verification Methods per Acceptance Criterion

| Method | Required Evidence | Minimum Standard |
|--------|-------------------|------------------|
| `test` | A-layer test output | All specified tests pass; coverage meets spec threshold |
| `screenshot` | A-layer screenshot file | Visual matches spec description; no obvious defects |
| `log` | A-layer log output | No errors; expected info messages present |
| `human_acceptance` | A-layer runtime_state + **Human Gate record** | **Verification Agent MUST NOT mark as verified**. Only user explicit confirmation at a Human Gate qualifies. |
| `command_output` | A-layer command_output | Output matches expected pattern |

## Evidence Collection Procedure

1. **Before claiming completion**, Verification Agent MUST:
   - Read the acceptance criteria from `sdd_spec.yaml`
   - For each criterion, collect the specified evidence type
   - Record all evidence in `evidence_pack.yaml`
   - Mark each evidence item as `verified: true` or `verified: false` with explanation

2. **Verdict rules**:
   - `all_criteria_met == true` ONLY if every criterion has `verified: true` A-layer evidence
   - `all_criteria_met == false` if ANY criterion lacks evidence or has `verified: false`
   - `recommendation == "pass"` requires `all_criteria_met == true`
   - `recommendation == "blocked"` if defects found that require re-implementation
   - `recommendation == "partial"` if some criteria met but others need human judgment

3. **Fix Verification** (when loop returns from E7 to E5):
   - Create `fix_verification.yaml` documenting:
     - Defect ID and description
     - Root cause analysis
     - Fix approach
     - Files modified
     - Re-verification evidence
   - Update `evidence_pack.yaml` with new verification results
   - Append trace entry to `phase_history.yaml`

4. **B-layer evidence**:
   - May be included for context
   - May NOT be the sole evidence for any criterion
   - Must be clearly labeled as B-layer
