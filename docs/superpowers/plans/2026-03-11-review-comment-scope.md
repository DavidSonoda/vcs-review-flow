# Review Comment Scope Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add normalized MR/PR comment fetching and a two-step confirmation flow for code-review comments and discussion comments.

**Architecture:** Keep target resolution in `scripts/resolve_review_target.sh` and add a separate `scripts/fetch_review_comments.sh` for remote comment intake. Update the skill and supporting docs to insert the new comment-scope step before worktree preparation, and verify behavior with shell-based tests that stub GitHub and GitLab CLI responses.

**Tech Stack:** Bash, `jq`, `gh`, `glab`

---

## Chunk 1: Comment Helper Contract

### Task 1: Add failing tests for GitHub comment splitting

**Files:**
- Create: `tests/test_fetch_review_comments.sh`
- Test: `tests/test_fetch_review_comments.sh`

- [ ] **Step 1: Write the failing test**

Add a test that stubs `gh api` for:
- `repos/<slug>/pulls/<number>/comments`
- `repos/<slug>/issues/<number>/comments`

Assert that JSON output reports:
- `code_review_comments.count == 1`
- `discussion_comments.count == 1`

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: FAIL because `scripts/fetch_review_comments.sh` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/fetch_review_comments.sh` with argument parsing and GitHub JSON normalization.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: PASS for the GitHub assertions.

### Task 2: Add failing tests for GitLab comment splitting

**Files:**
- Modify: `tests/test_fetch_review_comments.sh`
- Test: `tests/test_fetch_review_comments.sh`

- [ ] **Step 1: Write the failing test**

Add a GitLab fixture where one note has position metadata and one note is a plain discussion note.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: FAIL because GitLab classification is not implemented yet.

- [ ] **Step 3: Write minimal implementation**

Extend `scripts/fetch_review_comments.sh` to normalize GitLab discussions into the two categories and skip system notes.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: PASS for the GitLab assertions.

## Chunk 2: Documentation Flow

### Task 3: Add failing documentation checks for the two-step confirmation flow

**Files:**
- Modify: `tests/test_fetch_review_comments.sh`
- Modify: `SKILL.md`
- Modify: `README.md`
- Modify: `docs/examples.md`

- [ ] **Step 1: Write the failing test**

Add assertions that the skill docs mention:
- comment summary fetch after target resolution
- separate confirmation for `code-review comments`
- separate confirmation for `discussion comments`

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: FAIL because the docs do not mention the new flow yet.

- [ ] **Step 3: Write minimal implementation**

Update the docs to describe the helper and the two-step scope confirmation flow.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: PASS for the documentation checks.

## Chunk 3: Verification

### Task 4: Final verification

**Files:**
- Test: `tests/test_fetch_review_comments.sh`

- [ ] **Step 1: Run the full test script**

Run: `bash tests/test_fetch_review_comments.sh`
Expected: PASS

- [ ] **Step 2: Inspect repo status**

Run: `git status --short`
Expected: Modified docs, scripts, and test files only.
