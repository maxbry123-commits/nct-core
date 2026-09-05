---
name: dispatching-parallel-agents
description: Use to run multiple subagents concurrently on independent tasks
---

# Dispatching Parallel Agents

## Overview

Pattern for dispatching multiple subagents to work on independent tasks simultaneously.

**Core principle:** Parallel execution of strictly independent implementation or investigation domains.

> v3.0: Enhanced with Anthropic coordinator patterns — synthesis iron law, continue/spawn matrix, concurrency management.

## The Pattern

### 1. Identify Independent Domains
Group tasks by what's independent:
- File A tests: Tool approval flow
- File B tests: Batch completion behavior
- File C tests: Abort functionality

Each domain is independent — fixing one doesn't affect the others.

### 2. Create Self-Contained Agent Tasks

> **Iron Law: Workers can't see your conversation.** Every prompt must be self-contained with everything the worker needs.

Each agent gets:
- **Specific scope:** One test file or subsystem
- **Full context:** File paths, line numbers, error messages — not "based on earlier findings"
- **Clear goal:** Make these tests pass
- **Purpose statement:** Why this matters (helps worker calibrate depth)
- **Constraints:** Don't change other code
- **Expected output:** Summary of what you found and fixed

### 3. Dispatch with Concurrency Rules

```typescript
// Read-only tasks (research) → parallel freely
Task("Research auth system — find token handling in src/auth/")
Task("Research session management — how are sessions stored?")
Task("Research test helpers for auth")

// Write tasks → one at a time per file area
Task("Fix auth validation in src/auth/validate.ts")
// Wait for completion before dispatching overlapping writes
Task("Fix session expiry in src/auth/session.ts")
```

**Concurrency management:**

| Task Type | Rule |
|-----------|------|
| Read-only (research) | Run in parallel freely |
| Write-heavy (implementation) | One at a time per set of files |
| Verification | Can run alongside implementation on different file areas |

### 4. Synthesize and Integrate

When agents return:
1. **Read each summary** — Understand what changed (this is YOUR job, don't delegate)
2. **Synthesize findings** — Write specific specs if follow-up work needed
3. **Check for conflicts** — Did agents edit same code?
4. **Run full suite** — Verify all fixes work together
5. **Decide continue vs spawn** for next phase

## Continue vs Spawn Decision

After a worker completes, decide whether to reuse or spawn fresh:

| Situation | Action | Why |
|-----------|--------|-----|
| Worker researched exactly the files to edit | **Continue** | Already has files in context |
| Research was broad, implementation is narrow | **Spawn fresh** | Avoid exploration noise |
| Correcting a failure | **Continue** | Has error context |
| Verifying another worker's code | **Spawn fresh** | Fresh eyes, no bias |
| Wrong approach entirely | **Spawn fresh** | Avoid anchoring on failed path |
| Unrelated task | **Spawn fresh** | No useful context |

**No universal default.** High context overlap → continue. Low overlap → spawn fresh.

## Synthesis Anti-Patterns

| ❌ Anti-Pattern | ✅ Correct |
|----------------|-----------|
| "Based on your findings, fix it" | Write specific spec with file paths + line numbers |
| "The worker found an issue, please fix" | "Fix null pointer at src/auth/validate.ts:42 — add null check before user.id" |
| Sending one worker to check another | Workers report to you; you synthesize |
| Predicting worker results | Wait for actual results, then synthesize |

## Agent Prompt Structure

Good agent prompts are:
1. **Self-contained** — All context included (workers can't see your conversation)
2. **Synthesized** — Proves you understood the problem, not delegating understanding
3. **Focused** — One clear problem domain
4. **Purposeful** — Includes why this matters
5. **Specific about output** — What should the agent return?

```markdown
## Context
Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts:

1. "should abort tool with partial output capture" - expects 'interrupted at' in message
2. "should handle mixed completed and aborted tools" - fast tool aborted instead of completed
3. "should properly track pendingToolCount" - expects 3 results but gets 0

## Purpose
These are the last blockers before we can merge the feature branch.

## Task
1. Read the test file and understand what each test verifies
2. Identify root cause - timing issues or actual bugs?
3. Fix by:
   - Replacing arbitrary timeouts with event-based waiting
   - Fixing bugs in abort implementation if found
   - Adjusting test expectations if testing changed behavior

Do NOT just increase timeouts - find the real issue.

## Constraints
- Only modify files in src/agents/
- Do NOT change production code outside abort.ts

## Expected Output
Summary of root cause and changes made. Commit hash.
```

## Common Mistakes
**❌ Too broad:** "Fix all the tests" — agent gets lost
**✅ Specific:** "Fix agent-tool-abort.test.ts" — focused scope

**❌ No context:** "Fix the race condition" — agent doesn't know where
**✅ Context:** Paste the error messages and test names

**❌ No constraints:** Agent might refactor everything
**✅ Constraints:** "Do NOT change production code" or "Fix tests only"

**❌ Lazy delegation:** "Based on earlier findings, fix it"
**✅ Synthesized spec:** Specific file paths, line numbers, what to change

## When NOT to Use
- **Related failures:** Fixing one might fix others — investigate together first
- **Need full context:** Understanding requires seeing entire system
- **Exploratory debugging:** You don't know what's broken yet
- **Shared state:** Agents would interfere (editing same files, using same resources)

## Key Benefits
1. **Parallelization** — Multiple investigations happen simultaneously
2. **Focus** — Each agent has narrow scope, less context to track
3. **Independence** — Agents don't interfere with each other
4. **Speed** — 3 problems solved in time of 1
5. **Synthesis quality** — Coordinator proves understanding before delegating

## Verification
After agents return:
1. **Read each summary** — This is YOUR job, don't delegate understanding
2. **Synthesize** — Combine findings into a coherent picture
3. **Check for conflicts** — Did agents edit same code?
4. **Run full suite** — Verify all fixes work together
5. **Spawn fresh verifier** — Fresh eyes, no implementation bias

## Related Skills
- `coordinator-mode` — Full multi-agent coordination SOP
- `subagent-driven-development` — Per-task dispatch with review
- `iterative-retrieval` — Progressive context gathering for workers
- `verification-before-completion` — Evidence-based verification
