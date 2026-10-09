---
name: development-workflow
description: >-
  Use when starting, planning, implementing, verifying, or delivering a Ruby on Rails feature that benefits from a structured requirements-to-delivery workflow.
---

# Development Workflow

## Purpose

Orchestrate feature development with a lightweight specification-driven process. Keep the expected behavior separate from the technical design, implementation, verification, and delivery steps.

Use this skill as the workflow coordinator. Delegate detailed Rails, frontend, testing, Git, and pull-request rules to the relevant specialized skills.

## General Rules

- Read `AGENTS.md` and applicable repository instructions before starting.
- Inspect relevant existing code, tests, routes, schemas, and documentation before proposing changes.
- Do not invent unclear business rules or silently choose between materially different behaviors.
- Keep specifications independent of Rails classes, migrations, file names, and implementation details.
- Prefer the simplest maintainable solution that follows existing project conventions.
- Write focused automated tests for relevant behavior.
- Keep documentation synchronized with approved decisions and implementation outcomes.
- Do not introduce unrelated refactors, dependencies, or cleanup.
- Never commit or open a pull request without explicit authorization.

## Choosing the Workflow Size

Scale the process to the feature:

- **Small change:** Resolve ambiguity in chat, write a concise behavioral summary and implementation plan, then implement and verify.
- **Medium or complex feature:** Create the feature documents described below and use the phase gates.
- **Existing feature work:** Resume from the current artifacts and repository state; do not restart completed phases.

## Phase 1 — Discover

Goal: understand the problem before designing a solution.

1. Understand the user’s objective and desired outcome.
2. Inspect relevant product or domain documentation.
3. Identify actors, expected behavior, business rules, and data boundaries.
4. Identify invalid inputs, edge cases, authorization concerns, and security risks.
5. Ask focused questions about material ambiguities.
6. Summarize the agreed requirements.

Do not modify application code during discovery.

**Gate:** Actors, behavior, important business decisions, and scope are clear.

## Phase 2 — Specify

Goal: define the behavioral contract without prescribing implementation.

For medium or complex features, create:

`docs/features/<feature-name>/spec.md`

Include:

- Objective and scope.
- User stories when they clarify the behavior.
- Functional requirements.
- Business and authorization rules.
- Acceptance criteria.
- Positive, negative, and boundary scenarios.
- Explicit out-of-scope behavior.

If a feature-specification skill is available, use it. Otherwise, use this structure.

**Gate:** Present the specification for approval before creating the technical plan.

## Phase 3 — Plan

Goal: design an implementation consistent with the existing application.

Inspect:

- Models, associations, and domain objects.
- Controllers, routes, and authentication.
- Views, helpers, Form Objects, and components.
- Database schema and constraints.
- Existing tests and repository conventions.

For medium or complex features, create:

`docs/features/<feature-name>/plan.md`

Include:

- Technical approach and data flow.
- Files or subsystems affected.
- Database changes and compatibility considerations.
- Test strategy.
- Authorization and security considerations.
- Risks, trade-offs, and verification commands.

Route to the relevant skills:

- `rails-domain-and-queries` for models, Domain Objects, Service Objects, Query Objects, Policy Objects, and Value Objects.
- `rails-frontend-standards` for views, helpers, Form Objects, ViewComponents, Presenters, Decorators, Turbo, and Stimulus.
- `rails-testing-standards` for test structure, fixtures, integration tests, and system tests.

**Gate:** Present the implementation plan for approval before implementation.

## Phase 4 — Tasks

Goal: divide the approved plan into executable increments.

For medium or complex features, create:

`docs/features/<feature-name>/tasks.md`

Each task must:

- Have one clear objective.
- Be small enough to implement and verify.
- Reference the relevant requirement or acceptance criterion.
- State expected verification.
- Identify dependencies.

Prefer vertical increments that deliver testable behavior. Update task status as work progresses.

## Phase 5 — Implement

Goal: implement the approved tasks incrementally.

For each task:

1. Read the relevant specification, plan, and task details.
2. Identify the expected behavior and affected boundaries.
3. Write or update focused automated tests.
4. Implement the minimum code necessary.
5. Run the focused test suite.
6. Refactor while keeping tests passing.
7. Update the task status and feature documentation when decisions change.

Do not change approved business rules without confirmation. Do not add speculative abstractions or dependencies.

## Phase 6 — Verify

Goal: prove that the implementation matches the approved behavior.

Verify:

- Every acceptance criterion has evidence.
- Relevant automated tests pass.
- Authentication, authorization, and data isolation are correct.
- Database constraints and validation boundaries are appropriate.
- Existing behavior remains intact.
- Documentation matches the implementation.
- The diff contains no unrelated changes.

Use `verification-before-completion` before claiming completion. Use code-review guidance when available, and report findings by severity. Fix confirmed issues and rerun affected tests.

**Gate:** Present verification results and any remaining risks before delivery.

## Phase 7 — Deliver

Goal: prepare the completed feature for integration.

1. Confirm all required tasks are complete.
2. Ensure specification, plan, and task documents reflect the implementation.
3. Summarize changes and verification evidence.
4. Identify remaining risks or follow-up work.
5. Prepare commit or pull-request content only when requested.

Use `git-commit-workflow` for commit preparation and `github-pr-workflow` for pull-request preparation. Both workflows require explicit authorization before external or Git history changes.

## Resuming Work

When continuing an existing feature:

1. Read `spec.md`, `plan.md`, and `tasks.md` when present.
2. Inspect repository status and the current Git diff.
3. Identify completed, active, and pending tasks.
4. Check for inconsistencies between documentation and code.
5. Continue from the earliest incomplete phase or task.

Do not redo completed discovery, specification, or planning without evidence that the approved decisions changed.

## Definition of Done

- [ ] Specification reflects approved behavior, when a specification was required.
- [ ] Acceptance criteria have verification evidence.
- [ ] Relevant automated tests pass.
- [ ] Authentication, authorization, and data isolation have been reviewed.
- [ ] No unintended changes remain.
- [ ] Documentation is synchronized with the implementation.
- [ ] Code has been reviewed at the appropriate level.
- [ ] Commit or pull-request delivery is explicitly authorized.
