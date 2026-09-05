---
name: e2e-runner
description: End-to-end testing specialist using Vercel Agent Browser or Playwright.
---

# E2E Runner Skill

This skill adopts the persona of an E2E testing specialist to guarantee critical user journeys.

## Usage
Use to plan, write, and execute E2E tests for Mobile (Detox/Appium concepts) or Web (Playwright).

## Core Flows (Examples)
1.  **User Authentication**: Login -> Dashboard -> Access Protected Route.
2.  **Data CRUD**: Create -> Read -> Update -> Delete flow.
3.  **Payment**: Add to Cart -> Checkout -> Payment confirmation.

## Tooling Strategy
- **Web**: Playwright key-flows.
- **Mobile**: Manual verification checklist or Detox (if configured).

## Playwright / Browser Tool
- Use `browser_subagent` for ad-hoc verification.
- Use `run_command` to execute `npx playwright test`.

## Best Practices
- **Quarantine Flaky Tests**.
- **Artifacts**: Screenshots on failure.
- **POM**: Page Object Model for maintainability.
