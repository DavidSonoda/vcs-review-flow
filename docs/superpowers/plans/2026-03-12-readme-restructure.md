# README Restructure Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the repository documentation so the root README is a brief repo-level landing page and `skills/review-pr/README.md` becomes the full guide for the `review-pr` skill, including a Mermaid workflow diagram.

**Architecture:** Keep the documentation split explicit: root `README.md` handles discovery, install, and update guidance for the repo as a whole, while a new skill-local README holds the operational detail that previously lived at the root. Update the existing shell documentation test so it verifies the new boundary instead of forcing duplicated content across both files.

**Tech Stack:** Markdown, Mermaid, Bash shell tests

---

## File Structure

- Modify: `README.md`
- Create: `skills/review-pr/README.md`
- Modify: `tests/test_fetch_review_comments.sh`

## Chunk 1: Rewrite The Repo-Level README

### Task 1: Add a failing documentation test for the new README split

**Files:**
- Modify: `tests/test_fetch_review_comments.sh`
- Modify: `README.md`
- Create: `skills/review-pr/README.md`

- [ ] **Step 1: Rewrite the documentation assertions to match the approved split**

Update `test_docs_cover_two_step_scope_flow()` so it checks:
- root `README.md` title is `VCS Review Flow`
- root `README.md` links to `skills/review-pr/README.md`
- root `README.md` includes quickstart install and update commands
- root `README.md` does not need to carry the detailed review-flow assertions anymore
- `skills/review-pr/README.md` carries the detailed workflow, safety, and command assertions that used to live at the root
- `skills/review-pr/README.md` contains a Mermaid flowchart block

- [ ] **Step 2: Run the documentation test to verify it fails**

Run:

```bash
bash tests/test_fetch_review_comments.sh
```

Expected: FAIL because `skills/review-pr/README.md` does not exist yet and the current root README title/content does not match the new assertions.

- [ ] **Step 3: Rewrite the root README as a repo landing page**

Update `README.md` to:
- use the title `VCS Review Flow`
- describe the repo as a collection of VCS review skills
- include only brief sections for quickstart, available skills, updates, advanced manual install, and repository layout
- link to `skills/review-pr/README.md`
- remove the detailed workflow walkthrough and long command catalog

- [ ] **Step 4: Re-run the documentation test**

Run:

```bash
bash tests/test_fetch_review_comments.sh
```

Expected: still FAIL because the skill-local README is not written yet.

- [ ] **Step 5: Commit**

```bash
git add README.md tests/test_fetch_review_comments.sh
git commit -m "docs: slim root readme for repo overview"
```

## Chunk 2: Create The Skill-Local README And Flowchart

### Task 2: Add the detailed `review-pr` guide

**Files:**
- Create: `skills/review-pr/README.md`
- Verify: `skills/review-pr/SKILL.md`
- Verify: `skills/review-pr/docs/examples.md`

- [ ] **Step 1: Draft the skill README structure**

Create `skills/review-pr/README.md` with these sections:
- title and overview
- `What It Does`
- `Prerequisites`
- `Install`
- `How It Works`
- `Flowchart`
- `Local Development`
- `Safety Rules`
- `Related Files`

- [ ] **Step 2: Add the Mermaid flowchart**

Include a Mermaid block that shows:

```text
repo root -> platform detection -> MR/PR resolution -> review comment fetch
-> code-review scope choice -> discussion scope choice -> repo policy inspection
-> worktree sync/create -> review -> validation -> verification confirmation
-> change plan -> finish option
```

Include the three finish options:
- implement on the source branch
- implement then merge or cherry-pick elsewhere
- post a comment-only proposal

- [ ] **Step 3: Move the detailed command catalog into the skill README**

Document the local-development commands using `skills/review-pr/scripts/...` paths for:
- `detect_platform.sh`
- `resolve_review_target.sh`
- `repo_policy.sh`
- `fetch_review_comments.sh`
- `worktree_sync.sh`
- `post_review_comment.sh`

- [ ] **Step 4: Move the operational rules into the skill README**

Cover:
- code-review vs discussion-scope prompts
- resolved-thread exclusion
- outdated-thread validation
- same-pattern candidate rules
- verification-report confirmation
- safety stops and worktree rules

- [ ] **Step 5: Re-run the documentation test**

Run:

```bash
bash tests/test_fetch_review_comments.sh
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add skills/review-pr/README.md tests/test_fetch_review_comments.sh
git commit -m "docs: add review-pr skill guide"
```

## Chunk 3: Final Verification

### Task 3: Verify the documentation split end to end

**Files:**
- Verify: `README.md`
- Verify: `skills/review-pr/README.md`
- Verify: `tests/test_fetch_review_comments.sh`

- [ ] **Step 1: Run the targeted documentation regression test**

Run:

```bash
bash tests/test_fetch_review_comments.sh
```

Expected: PASS.

- [ ] **Step 2: Run the full existing shell suite as a regression check**

Run:

```bash
bash tests/test_install_skill.sh
bash tests/test_npm_wrapper.sh
bash tests/test_review_issue_clustering.sh
bash tests/test_review_validation_dispatch.sh
```

Expected: PASS.

- [ ] **Step 3: Scan for stale README assumptions**

Run:

```bash
rg -n "What The Skill Does|Workflow Summary|Local Development Commands|Safety Rules" README.md skills/review-pr/README.md tests
```

Expected: the detailed sections appear in `skills/review-pr/README.md`, not in the root README.

- [ ] **Step 4: Inspect the final diff**

Run:

```bash
git status --short
git diff --stat
```

Expected: only the root README, the new skill README, the documentation test, and any related plan/spec files are changed.

- [ ] **Step 5: Commit the completed documentation migration**

If the earlier chunk commits were not created, finish with:

```bash
git add README.md skills/review-pr/README.md tests/test_fetch_review_comments.sh
git commit -m "docs: split repo and skill readmes"
```

Plan complete and saved to `docs/superpowers/plans/2026-03-12-readme-restructure.md`. Ready to execute?
