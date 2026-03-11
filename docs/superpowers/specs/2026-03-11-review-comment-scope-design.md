---
title: MR/PR Review Comment Scope Design
date: 2026-03-11
---

# MR/PR Review Comment Scope Design

## Goal

Extend `vcs-review-flow` so MR/PR intake can detect remote review feedback, split it into `code-review comments` and `discussion comments`, and ask the user in two separate confirmation steps whether each type should be included in the active review scope.

## Current State

- `scripts/resolve_review_target.sh` resolves normalized MR/PR metadata only.
- `SKILL.md`, `README.md`, and `docs/examples.md` describe target resolution, worktree sync, review, and finish options.
- No helper exists for reading remote comment state or normalizing comment payloads across GitHub and GitLab.

## Constraints

- Keep target resolution focused on MR/PR metadata.
- Normalize comment intake across GitHub and GitLab with one helper contract.
- Preserve the existing worktree-first review flow.
- Ask about comment scope only when comments exist for that category.
- Present the two comment categories separately and in order:
  1. `code-review comments`
  2. `discussion comments`

## Design

### New Helper

Add `scripts/fetch_review_comments.sh`.

Inputs:
- `--repo <path>`
- `--number <id>`
- optional `--platform <github|gitlab>`
- optional `--json`

Outputs:
- normalized shell-safe `key=value` lines by default
- structured JSON with separate sections for `code_review_comments` and `discussion_comments` when `--json` is used

JSON contract:

```json
{
  "platform": "github",
  "repository": "owner/repo",
  "number": "123",
  "code_review_comments": {
    "count": 1,
    "items": [
      {
        "id": "c1",
        "author": "reviewer",
        "body": "Nit: rename this helper",
        "path": "src/app.ts",
        "line": "42",
        "url": "https://example.test/comment/1",
        "created_at": "2026-03-11T08:00:00Z"
      }
    ]
  },
  "discussion_comments": {
    "count": 1,
    "items": [
      {
        "id": "d1",
        "author": "maintainer",
        "body": "Can we break this into two commits?",
        "url": "https://example.test/comment/2",
        "created_at": "2026-03-11T09:00:00Z"
      }
    ]
  }
}
```

### Platform Mapping

GitHub:
- `code-review comments`: `gh api repos/<slug>/pulls/<number>/comments`
- `discussion comments`: `gh api repos/<slug>/issues/<number>/comments`

GitLab:
- read MR discussions via `glab api projects/:fullpath/merge_requests/<number>/discussions --paginate`
- classify notes with diff position metadata as `code-review comments`
- classify non-system notes without diff position metadata as `discussion comments`

### Workflow Changes

Update the skill docs to insert a new step after target resolution:

1. Resolve target metadata.
2. Fetch comment summaries.
3. If code-review comments exist, ask whether to include them in review scope.
4. If discussion comments exist, ask whether to include them in review scope.
5. Carry only approved comment categories into the review context.
6. Continue with repo policy inspection, worktree sync, review, change plan, and finish options.

### Error Handling

- Stop if the platform CLI is missing.
- Stop if API auth fails.
- Return zero counts when a valid MR/PR has no comments in a category.
- Omit system-generated GitLab notes from both categories.

### Testing

Add shell-based tests that stub `gh` and `glab` so the helper can be verified offline.

Cover:
- GitHub split between review comments and issue comments
- GitLab split between diff-position notes and discussion notes
- empty comment sets
- shell output and JSON output

