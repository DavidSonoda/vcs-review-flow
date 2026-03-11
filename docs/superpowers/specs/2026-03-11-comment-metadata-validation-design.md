---
title: Comment Metadata And Validation Flow Design
date: 2026-03-11
---

# Comment Metadata And Validation Flow Design

## Goal

Extend `vcs-review-flow` so remote review comments preserve richer platform metadata, and so only user-approved comments enter a validation and fix-planning workflow.

## Current State

- `scripts/fetch_review_comments.sh` normalizes comment bodies and basic location fields.
- `SKILL.md`, `README.md`, and `docs/examples.md` describe a two-step scope choice for `code-review comments` and `discussion comments`.
- No contract exists for richer remote metadata such as line ranges, diff hunks, review sides, or GitLab SHA position state.
- No documented workflow exists for validating approved comments before presenting a fix plan.

## Constraints

- Preserve only remote metadata returned by GitHub and GitLab APIs.
- Do not read local repository files or attach code snippets.
- Only analyze comment categories the user explicitly approves for scope.
- Present a simple validation report before proposing fixes.
- Treat confirmed comments as valid in-scope issues even when tests do not yet cover them.

## Design

### Metadata Enrichment

Keep `scripts/fetch_review_comments.sh` as the single normalization point.

GitHub code-review comment items must preserve:
- identity fields: `id`, `author`, `body`, `url`, `created_at`
- file context: `path`, `line`, `start_line`
- review placement: `side`, `start_side`, `subject_type`
- historical location: `original_line`, `original_start_line`, `original_position`
- diff linkage: `commit_id`, `original_commit_id`, `diff_hunk`

GitLab code-review comment items must preserve:
- identity fields: `id`, `author`, `body`, `url`, `created_at`
- normalized position fields: `path`, `line`, `new_path`, `old_path`, `new_line`, `old_line`
- merge base linkage: `base_sha`, `start_sha`, `head_sha`
- placement fields: `position_type`, `line_range`
- raw remote `position` object for any platform-specific details that are not worth flattening

Discussion comments remain lightweight unless the platform already exposes stable remote metadata without extra local lookups.

### Scope And Validation Workflow

The review flow remains:
1. resolve target
2. fetch normalized comments
3. ask whether to include `code-review comments`
4. ask whether to include `discussion comments`

After those decisions:
- build the active review scope from only the approved categories
- if no categories are approved, continue the review flow without comment-derived issues
- if categories are approved, dispatch several subagents in parallel to validate whether the selected comments still make sense

Each validation subagent should classify selected comments as:
- `likely_valid`
- `unclear`
- `likely_stale`

Each classification must include short reasoning tied to the MR/PR context.

### Verification Report

Before planning fixes, present a simple verification report that includes:
- approved categories
- each selected comment or thread
- validation status
- a short reason

Then ask the user for confirmation.

### Fix Planning Rule

If the user confirms the verification report:
- produce a fix plan from the confirmed in-scope comments
- do not exclude a confirmed issue just because automated tests do not cover it
- later implementation may still add or update tests, but test absence is not a gate on issue validity

## Testing

Add shell-based tests that stub `gh` and `glab` responses and assert the richer JSON contract.

Cover:
- GitHub review comments with line range and diff metadata
- GitLab review comments with `position` and `line_range`
- unchanged split between review comments and discussion comments
- docs describing approval-only validation and confirmation before fix planning
