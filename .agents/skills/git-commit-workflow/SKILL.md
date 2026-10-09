---
name: git-commit-workflow
description: >-
  Guidelines and strict discipline for inspecting repository changes, validating branch safety, organizing atomic changes, splitting commits, and generating Conventional Commits. Commits must NEVER be executed autonomously; a human engineer must explicitly request the commit.
---

# Git Commit Workflow & Safety Standards

This skill establishes the repository discipline for creating high-quality, reviewable, atomic, and safe Git commits.

---

## 1. Golden Rule: Explicit Human Request Required

> **MANDATORY INVARIANT:** AI agents MUST NEVER run `git commit` autonomously, automatically, or proactively. A commit must ONLY be executed when a human user explicitly requests it (e.g., *"faça um commit"*, *"commit these changes"*, *"please commit"*).
>
> Even after completing modifications, tests, or documentation, the agent must leave changes unstaged or staged in the working tree and present the results to the user. Never commit without direct human authorization.

---

## 2. Commit Philosophy

Every commit should:
- Represent **one logical change**.
- Be easy to review in isolation.
- Be easy to revert without cascading breakage.
- Communicate intent clearly to future maintainers.

### Prefer:
- Small, focused diffs.
- Clear separation of concerns.
- Explicit and intentional staging.

### Avoid:
- Monolithic commits bundling multiple unrelated changes.
- Mixing refactorings, formatting fixes, and features together.
- Vague commit messages (`WIP`, `fixes`, `update code`).

---

## 3. Protected Branch Rules

> **SAFETY INVARIANT:** Never commit directly to protected branches.

Protected branches include:
- `main`
- `production`

### If currently on a protected branch:
1. **HALT immediately.** Do not stage or commit files.
2. Warn the user clearly.
3. Suggest creating a feature, chore, or bugfix branch:
   ```bash
   git checkout -b <type>/<descriptive-name>
   ```

### 3.1 Branch Naming Pattern

Use:

```text
<type>/<descriptive-name>
```

Examples:

- `feat/add-dark-mode`
- `fix/handle-expired-token`
- `chore/update-dependencies`

---

## 4. Inspection Workflow Before Staging

Before staging any files, always inspect the full working tree state:

```bash
# 1. Verify current branch
git branch --show-current

# 2. Inspect modified, untracked, and deleted files
git status

# 3. Inspect unstaged changes
git diff

# 4. Inspect staged changes
git diff --staged

# 5. Check recent branch commit history
git log --oneline -5
```

---

## 5. Change Grouping & Commit Splitting

### Split changes into separate commits when:
- Refactoring and feature changes touch the same area but are conceptually independent.
- Formatting/lint fixes create visual diff noise.
- Dependency updates (`Gemfile.lock`, `package.json`) are independent of code changes.
- Generated files or schema dumps can be reviewed separately.
- Unrelated modules or layers (e.g., backend vs. documentation) changed simultaneously.

### Keep changes together in a single commit when:
- Tests directly validate the new or modified behavior.
- Database migrations directly correspond to model association/schema changes.
- A refactoring is an inseparable prerequisite for the feature.
- The changes are tightly coupled and breaking them apart would cause tests to fail in intermediate commits.

---

## 6. Conventional Commits Specification

Every commit message must follow the Conventional Commits format:

```
<type>(<scope>): <subject>

[optional body explaining context and motivation]
```

### 6.1 Allowed Types:
- `feat`: New feature or user-facing capability.
- `fix`: Bug fix.
- `refactor`: Code restructuring without functional behavior changes.
- `test`: Adding or correcting automated tests.
- `chore`: Tooling, configuration, dependencies, or repository maintenance.
- `docs`: Documentation updates only.
- `style`: Formatting, whitespace, or lint-only fixes (no code logic change).
- `perf`: Performance improvements.
- `ci`: Continuous integration scripts or workflows.
- `enhancment`: Enhancement changes.

### 6.2 Subject Formatting Rules:
- Use the **imperative mood** (e.g., *"add dark mode toggle"* rather than *"added dark mode toggle"* or *"adds dark mode toggle"*).
- Keep the subject line under **72 characters**.
- Do not capitalize the first letter of the subject.
- Do not place a period (`.`) at the end of the subject.

### Examples:
- **Good:** `feat(ui): add dark mode toggle`
- **Good:** `fix(api): handle expired access token`
- **Good:** `refactor(auth): simplify session cookie sanitization`
- **Good:** `test(views): add coverage for empty state`
- **Bad:** `update code`
- **Bad:** `fixes`
- **Bad:** `WIP on feature`
- **Bad:** `feat: added lots of stuff and refactored models and fixed bug`

---

## 7. Pre-Commit Verification Checklist

Before creating a commit:
1. [ ] **Explicit Human Request:** Did the human user explicitly ask or confirm to create the commit?
2. [ ] **Branch Safety:** Are you on a dedicated branch (NOT on `main` or `production`)?
3. [ ] **No Secrets:** Did you verify that no `.env` files, API keys, passwords, or credentials are staged?
4. [ ] **No Debug Artifacts:** Did you remove temporary `binding.pry`, `byebug`, `console.log`, or commented-out code?
5. [ ] **Tests Pass:** Did you run the targeted automated test suite for the modified files?
6. [ ] **Linters Pass:** Did you verify formatting/lint rules (e.g., `bundle exec rubocop`)?
7. [ ] **Atomic Scope:** Does the staged diff represent a single, cohesive logical change?
8. [ ] **Imperative Subject:** Does the commit message use the imperative mood and follow Conventional Commits?
