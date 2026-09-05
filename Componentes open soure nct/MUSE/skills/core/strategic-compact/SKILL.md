---
name: strategic-compact
description: Suggests manual context compaction at logical intervals to preserve context through task phases rather than arbitrary auto-compaction. Supports focus-aware compaction for targeted context preservation.
---

# Strategic Compact Skill

Suggests manual `/compact` at strategic points rather than relying on arbitrary auto-compaction.

## Why Strategic Compaction?

Auto-compaction triggers at arbitrary points:
- Often mid-task, losing important context
- No awareness of logical task boundaries
- Can interrupt complex multi-step operations

Strategic compaction at logical boundaries:
- **After exploration, before execution** — Compact research, keep plan
- **After completing a milestone** — Fresh start for next phase
- **Before major context shifts** — Clear old context before different task

## Focus-Aware Compaction (inspired by OpenClaw)

Blind compaction = blind discards. Focus-directed compaction = preserving key information.

**Usage**: Specify what to preserve when manually compacting.

```
Scenario: Completed 3 hours of debugging, now starting a new feature
✅ /compact preserve root cause analysis and fix approach, discard trial-and-error debugging
❌ /compact (blind compaction may discard root cause analysis)
```

**Common focus templates**:

| Scenario | Focus Directive |
|----------|----------------|
| After debugging | `Preserve root cause and fix approach, discard trial-and-error` |
| After planning | `Preserve final plan and key decisions, discard alternative discussions` |
| After code review | `Preserve items to change, discard confirmed-OK sections` |
| After strategy discussion | `Preserve strategic decisions and metrics, discard brainstorming process` |
| After multi-file edits | `Preserve which files changed and why, discard file content details` |

## When to Trigger Compaction

| Signal | Action |
|--------|--------|
| Completed a full milestone | ✅ Good time to compact |
| Switching from exploration to execution | ✅ Good time to compact |
| Debugging complete, starting new feature | ✅ Good time to compact |
| In the middle of multi-step implementation | ❌ Do NOT compact |
| Still analyzing a problem | ❌ Do NOT compact |
| `/ctx` shows 60-70% consumed | 🟡 Consider compacting |
| `/ctx` shows ≥ 80% consumed | 🔴 Must exit (constitution rule) |

## Hook Setup

Add to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "tool == \"Edit\" || tool == \"Write\"",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/strategic-compact/suggest-compact.sh"
      }]
    }]
  }
}
```

## Configuration

Environment variables:
- `COMPACT_THRESHOLD` - Tool calls before first suggestion (default: 50)

## Best Practices

1. **Compact with focus** — Always specify what to preserve, never compact blindly
2. **Write memory before compacting** — Save key information to `memory/YYYY-MM-DD.md` first
3. **Never compact mid-task** — Maintain complete context during multi-step implementations
4. **Pair with /ctx** — 60-70% consider compacting, ≥ 80% must exit

## Pre-Compaction Protocol (MUSE — derived from LCM compact:before)

**MUST** execute in order before compaction:
1. **Persist**: Write current task progress to `memory/YYYY-MM-DD.md`
2. **Mark protected zone**: Mark last 5 conversation turns as "non-compactable" (≈ LCM freshTailCount=32)
3. **Extract key decisions**: Scan content about to be compacted, extract key decisions/data to memory
4. **Notify user**: Inform about upcoming compaction, list what will be preserved

> **Principle: Persist first, then compact. Never discard information without a backup.**

## Post-Compaction Injection (MUSE — derived from OpenClaw postCompactionSections)

**MUST** re-internalize the following after compaction:
1. First 4 lines of `CLAUDE.md` (7 iron laws + priority chain)
2. Currently `[/]` in-progress tasks from `task.md`
3. Today's `memory/` snapshot (just written)
4. Any focus-aware specified preservation items

> **Principle: Compaction ≠ forgetting. Core identity and current context must be restored immediately after compaction.**
