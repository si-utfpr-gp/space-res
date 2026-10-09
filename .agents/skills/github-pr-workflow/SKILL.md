---
name: github-pr-workflow
description: >-
  Standards and workflows for inspecting branch diffs, validating readiness, and opening high-quality GitHub Pull Requests via GitHub MCP or GitHub CLI. Use whenever preparing, summarizing, drafting, or creating pull requests.
---

# GitHub Pull Request Standards & Workflow

This skill establishes the repository conventions and disciplined workflow for inspecting branch readiness, formatting, and opening high-quality GitHub Pull Requests (PRs).

---

## 1. Pull Request Philosophy

Each pull request must represent **one cohesive objective**:
- Easy to review.
- Easy to test and validate in staging.
- Easy to revert if unforeseen issues occur in production.
- Grounded strictly in the actual diff (never inventing or exaggerating claims).

### Avoid:
- Monolithic "kitchen sink" PRs bundling multiple unrelated features.
- Opening PRs with known failing tests or unresolved merge conflicts.
- Vague or generic descriptions that force the reviewer to deduce intent from raw code.

---

## 2. Safety & Branch Validation

> **CRITICAL RULE:** Never open a pull request directly from `main` or `production`.

Before drafting or creating a PR, verify:
1. **Current Branch:** Must be a dedicated feature, bugfix, refactor, or chore branch:
   ```bash
   git branch --show-current
   ```
2. **Diff Against Base:** Inspect all commits and file changes that will be included in the PR against the base branch (usually `main` or the epic branch):
   ```bash
   # Inspect list of commits on this branch
   git log --oneline origin/main..HEAD

   # Inspect summary of changed files
   git diff --stat origin/main...HEAD
   ```
3. **Working Tree Cleanliness:** Ensure all intended changes are committed and no untracked or unwanted files are left behind (`git status`).

### 2.1 GitHub Account and Repository Discovery

Before any GitHub action:

1. Discover the repository owner and name from `git remote -v`.
2. Inspect all authenticated GitHub CLI accounts with `gh auth status`.
3. Verify the active identity:
   ```bash
   gh api user --jq .login
   ```
4. Confirm repository access:
   ```bash
   gh repo view <owner>/<repo>
   ```
5. If multiple accounts can access the repository and the correct account is ambiguous, ask the user before continuing.

Prefer GitHub CLI when explicit account selection is required. Use MCP only when its connected account and permissions are confirmed.

---

## 3. Pull Request Title Convention

The PR title must strictly follow the **Conventional Commits** specification:

```
<type>(<scope>): <imperative summary>
```

### Examples:
- `feat(staff): introduce multi-profile hub and school switcher`
- `fix(pickups): prevent duplicate real-time chat broadcasts`
- `refactor(auth): sanitize post-login return paths against open redirects`
- `chore(skills): reorganize and formalize agent skills structure`

---

## 4. Standard Pull Request Body Template

Every pull request description must be structured using the following four mandatory sections:

```markdown
## Description
[A concise summary explaining what this pull request accomplishes and what user-facing or architectural changes it introduces.]

## Motivation
[Why is this change necessary? Mention the bug being resolved, feature requirement, or architectural cleanup.]

## Changes
- [Key change 1: e.g., Extract Staff::Pickups::DashboardQuery to eliminate N+1 queries]
- [Key change 2: e.g., Migrate manager login to unified Web::Auth::SessionsController]
- [Key change 3: e.g., Add granular system tests for gate arrival alerts]

## Tests
- [Specific test suite executed and passed, e.g., bin/rails test test/controllers/web/staff/]
- [System test suite passed in headless Chrome, e.g., bin/rails test test/system/staff/]
- [Linters verified, e.g., bundle exec rubocop]
```

### Strict Rule on Test Claims:
Never state that tests or linters passed unless they were **actually executed and verified with 0 failures and 0 errors**. Do not fabricate test coverage.

---

## 5. Creating the Pull Request

### Option A: GitHub MCP Server (Recommended)
When GitHub MCP tools are available in the session:
1. Identify `owner`, `repo`, `head` (current branch), `base` (target branch, default `main` unless targeting an epic branch).
2. Format the title and body according to the template above.
3. Invoke the MCP tool to open the PR.

### Option B: GitHub CLI (`gh`) Fallback
When executing via shell command:
```bash
gh pr create \
  --base main \
  --head $(git branch --show-current) \
  --title "feat(scope): concise title" \
  --body "$(cat <<'EOF'
## Description
...

## Motivation
...

## Changes
- ...

## Tests
- ...
EOF
)"
```

---

## 6. Pre-PR Checklist

Before opening a pull request:
1. [ ] Is the branch cleanly branched from and up to date with the base branch?
2. [ ] Are all commits formatted using Conventional Commits?
3. [ ] Are temporary debug logs, print statements, and commented-out code removed?
4. [ ] Did all automated tests pass locally?
5. [ ] Does the PR title follow `<type>(<scope>): <summary>`?
6. [ ] Does the PR body contain all 4 mandatory sections (`Description`, `Motivation`, `Changes`, `Tests`)?
