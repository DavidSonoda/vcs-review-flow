# GitLab Note Resolution Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make GitLab MR comment normalization use note-level resolution state so resolved and unresolved review comments are classified correctly.

**Architecture:** Keep the normalized JSON contract unchanged and adjust only the GitLab normalization path in `fetch_review_comments.sh`. Add a regression test fixture shaped like GitLab MR `222`, where discussion objects omit `resolved` while resolvable diff notes carry mixed `resolved` values and non-resolvable update notes are present.

**Tech Stack:** Bash, jq, shell tests

---

## Chunk 1: Regression Test

### Task 1: Add the failing GitLab fixture and test

**Files:**
- Modify: `tests/test_fetch_review_comments.sh`
- Test: `tests/test_fetch_review_comments.sh`

- [ ] **Step 1: Write the failing test**

Add a GitLab API fixture for MR `222` with:
- one resolved resolvable diff note
- one unresolved resolvable diff note
- one non-resolvable update note sharing a discussion
- discussion objects that omit top-level `resolved`

Add assertions that expect:
- unresolved resolvable diff notes remain in `code_review_comments`
- resolved resolvable diff notes move to `excluded_resolved_comments`
- non-resolvable update notes do not enter either review bucket

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: FAIL because the current GitLab normalizer reads discussion-level resolution and leaves resolved notes active.

## Chunk 2: Minimal Fix

### Task 2: Prefer note-level GitLab resolution metadata

**Files:**
- Modify: `skills/review-pr/scripts/fetch_review_comments.sh`
- Test: `tests/test_fetch_review_comments.sh`

- [ ] **Step 1: Write minimal implementation**

Update GitLab review-note normalization to:
- prefer `.resolved`, `.resolved_by`, and `.resolved_at` from the note itself
- fall back to the discussion-level fields only when note-level fields are absent
- preserve the existing normalized output keys

- [ ] **Step 2: Run test to verify it passes**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: PASS

## Chunk 3: Verification

### Task 3: Re-run targeted validation

**Files:**
- Modify: none
- Test: `tests/test_fetch_review_comments.sh`

- [ ] **Step 1: Verify against the local regression test**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: PASS

- [ ] **Step 2: Verify against the live MR shape**

Run: `bash skills/review-pr/scripts/fetch_review_comments.sh --repo /Users/brainco/BrainCo/gitlab-projects/brainco-cloud-uac --platform gitlab --number 222 --json | jq '{code_review_count: .code_review_comments.count, excluded_resolved_count: .excluded_resolved_comments.count}'`
Expected: `code_review_count` reflects the unresolved notes and `excluded_resolved_count` reflects the resolved notes.
