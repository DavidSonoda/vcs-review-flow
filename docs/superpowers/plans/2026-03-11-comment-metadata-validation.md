# Comment Metadata And Validation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enrich normalized MR/PR review comments with richer remote metadata and document a validation-report gate for user-approved comments before fix planning.

**Architecture:** Keep `scripts/fetch_review_comments.sh` as the single normalization layer for GitHub and GitLab review comments. Extend only the remote metadata contract, then update the skill/docs so approved comment categories trigger parallel validation subagents, a simple verification report, user confirmation, and fix planning even when tests are missing.

**Tech Stack:** Bash, `jq`, `gh`, `glab`

---

## Chunk 1: Richer Comment Metadata

### Task 1: Add failing tests for GitHub remote metadata preservation

**Files:**
- Modify: `tests/test_fetch_review_comments.sh`
- Test: `tests/test_fetch_review_comments.sh`

- [ ] **Step 1: Write the failing test**

Extend the GitHub fixture with fields such as `start_line`, `side`, `start_side`, `diff_hunk`, `commit_id`, `original_commit_id`, `original_line`, and `original_start_line`.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: FAIL because the current normalization drops the richer GitHub metadata.

- [ ] **Step 3: Write minimal implementation**

Update `scripts/fetch_review_comments.sh` to preserve the richer GitHub review metadata in `code_review_comments.items[]`.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: PASS for the GitHub metadata assertions.

### Task 2: Add failing tests for GitLab remote metadata preservation

**Files:**
- Modify: `tests/test_fetch_review_comments.sh`
- Test: `tests/test_fetch_review_comments.sh`

- [ ] **Step 1: Write the failing test**

Extend the GitLab fixture with `base_sha`, `start_sha`, `head_sha`, `position_type`, and `line_range`.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: FAIL because the current normalization drops most GitLab position metadata.

- [ ] **Step 3: Write minimal implementation**

Update `scripts/fetch_review_comments.sh` to preserve normalized GitLab position metadata and the raw `position` object.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: PASS for the GitLab metadata assertions.

## Chunk 2: Workflow Documentation

### Task 3: Add failing documentation checks for validation and confirmation flow

**Files:**
- Modify: `tests/test_fetch_review_comments.sh`
- Modify: `SKILL.md`
- Modify: `README.md`
- Modify: `docs/examples.md`

- [ ] **Step 1: Write the failing test**

Add assertions that the docs mention:
- only approved comment categories are analyzed
- several subagents validate approved comments
- a simple verification report is shown
- user confirmation happens before fix planning
- confirmed comments remain in scope even without existing tests

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: FAIL because the docs do not yet describe the validation-report gate.

- [ ] **Step 3: Write minimal implementation**

Update the docs to describe the approved-comment validation workflow and the fix-plan rule.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: PASS for the documentation assertions.

## Chunk 3: Verification

### Task 4: Final verification

**Files:**
- Test: `tests/test_fetch_review_comments.sh`

- [ ] **Step 1: Run the full test script**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: PASS

- [ ] **Step 2: Inspect repo status**

Run: `git status --short`
Expected: Modified script, docs, tests, and new spec/plan files only.
