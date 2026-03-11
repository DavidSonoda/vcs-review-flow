---
name: vcs-review-flow
description: Use when you need to review or update the latest open GitLab merge request or GitHub pull request through a local worktree, or when a user provides a specific MR or PR number.
---

# VCS Review Flow

Use this skill when the user wants you to pull, review, or update a remote GitLab MR or GitHub PR through a local worktree instead of switching the current checkout.

## Prerequisites

- `git`
- `jq`
- `gh` for GitHub repositories
- `glab` for GitLab repositories

## Workflow

1. Resolve the repository root.

```bash
git rev-parse --show-toplevel
```

2. Detect the VCS platform.

```bash
bash scripts/detect_platform.sh --repo <repo-root>
```

3. Resolve the review target.

Latest open MR/PR:

```bash
bash scripts/resolve_review_target.sh --repo <repo-root> --latest
```

Specific MR/PR number:

```bash
bash scripts/resolve_review_target.sh --repo <repo-root> --number <number>
```

4. Fetch remote review comments for the resolved MR/PR.

```bash
bash scripts/fetch_review_comments.sh --repo <repo-root> --number <number> --platform <github|gitlab> --json
```

Rules:
- if `code-review comments` exist, ask the user whether to include code-review comments in scope before continuing
- if `discussion comments` exist, ask the user whether to include discussion comments in scope after the code-review comment decision
- only pull comment bodies into the active review context for the categories the user approved

5. Inspect repository policy before touching worktrees.

```bash
bash scripts/repo_policy.sh --repo <repo-root>
```

Read both `AGENTS.md` and `CLAUDE.md` when present. If they conflict on worktree location or workflow, surface that conflict instead of guessing.

6. Reuse or create the worktree for the MR/PR source branch.

```bash
bash scripts/worktree_sync.sh \
  --repo <repo-root> \
  --source-branch <source-branch> \
  --head-sha <head-sha>
```

Rules:
- if the matching worktree already exists locally, sync it to the latest remote branch head
- if the matching worktree does not exist, create it in the repo-approved location
- if the existing worktree has uncommitted changes, stop and ask before syncing

7. Run review from the prepared worktree.

If the environment exposes a review skill such as `requesting-code-review`, invoke it with:
- the user's review request
- the resolved base/head context
- the approved comment categories plus their pulled comment content
- the prepared worktree path

If no dedicated review skill is available, perform the review directly with a code-review mindset.

8. After review, produce a change plan.

The change plan must include:
- key findings being addressed
- likely files or areas to change
- implementation direction
- verification steps

9. Present exactly these finish options.

```text
1. Implement locally on the original source branch, commit, and push to update the MR/PR.
2. Implement locally on the original source branch, commit there, then merge or cherry-pick into a user-specified branch.
3. Do not implement locally; post the proposed changes as a GitLab/GitHub comment with concrete patch guidance.
```

## Safety Stops

- Stop if `gh` or `glab` is missing for the detected platform.
- Stop if authentication fails.
- Stop if there are no open MRs/PRs.
- Stop if the remote source branch no longer exists.
- Stop before syncing a dirty worktree.
- Never force-push unless the user explicitly asks.

## Quick Reference

Detect platform:

```bash
bash scripts/detect_platform.sh --repo <repo-root>
```

Resolve latest target:

```bash
bash scripts/resolve_review_target.sh --repo <repo-root> --latest
```

Resolve explicit target:

```bash
bash scripts/resolve_review_target.sh --repo <repo-root> --number 123
```

Inspect repo policy:

```bash
bash scripts/repo_policy.sh --repo <repo-root>
```

Sync worktree:

```bash
bash scripts/worktree_sync.sh --repo <repo-root> --source-branch feat/example --head-sha <sha>
```

Fetch review comments:

```bash
bash scripts/fetch_review_comments.sh --repo <repo-root> --number 123 --platform github --json
```

Post comment-only proposal:

```bash
bash scripts/post_review_comment.sh --repo <repo-root> --number 123 --body-file /tmp/review-plan.md
```
