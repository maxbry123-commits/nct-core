---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Reframes the problem, challenges assumptions, and outputs a design doc that downstream skills can read."
---

# Brainstorming — Reframe Before You Build

*Inspired by gstack's /office-hours. Upgraded to output standardized design docs.*

## Overview

Don't just ask "what do you want to build?" Ask "what pain are you solving?"
This skill reframes the problem before a line of code is written, then outputs
a design doc that feeds into `/sprint` downstream skills.

## The Process

### Phase 1: Reframe the Problem

Before exploring solutions, challenge the framing:

1. **Listen for pain, not features.** User says "add a dark mode toggle." 
   Ask: "What's the actual problem? Is it eye strain? Brand consistency? User requests?"
2. **Push back on scope.** User describes 10 features. Ask: "If you could only ship one this week, which one?"
3. **Challenge 3 premises.** Identify the user's hidden assumptions and question them explicitly.
   - "You're assuming users want X. What if they actually want Y?"
   - "You're assuming this needs to be real-time. Does it?"
   - "You're assuming mobile-first. What if desktop is the real use case?"

Rules:
- One question per message
- Multiple choice when possible
- Don't rush past reframing — this is the highest-leverage phase

### Phase 2: Explore Approaches

Once the real problem is clear:

1. **Generate 3 approaches** with different tradeoffs:
   - **Narrowest wedge** — ship in hours, validate the thesis
   - **Balanced** — ship in days, covers core use cases
   - **Full vision** — ship in weeks, comprehensive solution
2. **Recommend one** with clear reasoning
3. **Estimate effort** for each (hours, not story points)

Lead with your recommendation. Explain why.

### Phase 3: Present the Design

Once approach is chosen:

- Break into sections of 200-300 words
- After each section, ask: "Does this look right so far?"
- Cover: architecture, components, data flow, error handling, testing
- Apply ETHOS.md: Boil the Lake (do the complete thing), YAGNI (don't add what's not needed)

### Phase 4: Output Design Doc

Write a standardized design doc to `docs/plans/YYYY-MM-DD-<topic>-design.md`:

```markdown
# [Feature Name] Design Doc

## Problem
[1-2 sentences: the actual pain, not the feature request]

## Reframe
[How the problem was reframed during brainstorming]

## Approach
[Chosen approach and why. Brief mention of alternatives considered.]

## Scope
[What's IN scope and what's explicitly OUT]

## Technical Design
[Architecture, components, data flow, key decisions]

## Acceptance Criteria
[Numbered list of verifiable outcomes]

## Test Strategy
[What to test and how]

## Risks
[Top 2-3 risks and mitigations]
```

This doc is read by downstream skills:
- `writing-plans` reads it to create implementation plan
- `architect-agent` reads it for architecture review  
- `code-reviewer-agent` reads Acceptance Criteria to verify completeness

## Key Principles

- **Reframe first** — The best feature is often not what was originally requested
- **One question at a time** — Don't overwhelm with multiple questions
- **Ship the Narrowest Wedge** (from ETHOS.md) — Scope tight, validate fast
- **Three premises** — Always challenge at least 3 hidden assumptions
- **Design doc is the handoff** — Other skills read it, so make it precise
- **Be flexible** — Go back and clarify when something doesn't make sense
