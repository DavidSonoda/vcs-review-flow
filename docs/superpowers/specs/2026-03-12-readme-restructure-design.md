---
title: README Restructure Design
date: 2026-03-12
---

# README Restructure Design

## Goal

Restructure the repository documentation so the root `README.md` stays repository-scoped and brief, while the `review-pr` skill gets its own detailed guide in `skills/review-pr/README.md`, including a Mermaid flowchart that explains the skill workflow.

## Scope

This design covers:

- root `README.md` content and structure
- creation of `skills/review-pr/README.md`
- movement of skill-specific documentation from the root README into the skill README
- a Mermaid workflow diagram for `review-pr`

This design does not cover:

- changes to the skill behavior itself
- packaging or installer behavior changes
- additional new skills

## Current State

- The root `README.md` is titled `review-pr`, which incorrectly presents the repository as a single skill rather than a skill collection.
- The root README currently combines repository-level install/update guidance with the full `review-pr` skill guide.
- `skills/review-pr/` has no dedicated `README.md`.
- Skill-local docs currently exist only as `SKILL.md` and `docs/examples.md`.

## Constraints

- The root README should remain brief and repository-scoped.
- The repository title should be `VCS Review Flow`.
- The root README should still give users enough information to discover available skills and install them quickly.
- The `review-pr` skill should have a self-contained guide in its own directory.
- The workflow explanation in the skill README should include a rendered Mermaid diagram.
- The root README and skill README should not duplicate large sections of content.

## Design

### Root README

Retitle the root document to `VCS Review Flow`.

Purpose:
- describe the repository as a `skills.sh`-ready collection of VCS review skills
- give users the shortest path to install and update skills
- show which skills are currently available
- point readers into the relevant skill-local README for details

Required sections:

- `Quickstart`
- `Available Skills`
- `Updates`
- `Advanced Manual Install`
- `Repository Layout`

Content rules:
- keep the introduction to one short paragraph
- keep install instructions limited to the primary `skills.sh` command and the optional `@minakoto00/skills` shortcut
- keep update instructions limited to `npx skills check` and `npx skills update`
- list `review-pr` with a one-line description and a link to `skills/review-pr/README.md`
- do not include the workflow walkthrough, safety rules, or local script command catalog at the root

### Skill README

Create `skills/review-pr/README.md` as the canonical long-form guide for the `review-pr` skill.

Required sections:

- title and overview
- `What It Does`
- `Prerequisites`
- `Install`
- `How It Works`
- `Flowchart`
- `Local Development`
- `Safety Rules`
- `Related Files`

Content rules:
- explain the skill as a GitHub PR and GitLab MR review workflow
- keep install text aligned with the repo-level install commands
- include local-development commands that reference `skills/review-pr/scripts/`
- keep the detailed command catalog and operational notes here rather than at the repo root

### Mermaid Flowchart

Include a Mermaid flowchart in `skills/review-pr/README.md` that shows the high-level review flow.

The diagram should cover:

- resolve the repository root
- detect the VCS platform
- resolve latest or specific MR/PR
- fetch review comments
- decide whether code-review comments are in scope
- decide whether discussion comments are in scope
- inspect repo policy
- reuse or create the worktree
- run review in the worktree
- validate approved comments and same-pattern candidates
- confirm the verification report
- produce a change plan
- choose a finish option

The finish options should show:

- implement on the original source branch
- implement locally, then merge or cherry-pick into another branch
- post a comment-only proposal instead of implementing locally

The diagram should stay user-facing and readable rather than encoding low-level implementation details.

## Content Migration

Move these categories from the root README into the skill README:

- what the skill does
- workflow summary
- local development commands
- safety rules
- file references specific to `review-pr`

Leave only these categories at the root:

- repository introduction
- quickstart install commands
- update commands
- available skills list
- brief advanced-install note
- repository layout pointers

## Testing

Verification should cover:

- the root README title is `VCS Review Flow`
- the root README links to `skills/review-pr/README.md`
- `skills/review-pr/README.md` exists
- the skill README contains a Mermaid flowchart block
- the existing documentation tests still pass after being retargeted as needed

## Rollout

Ship the root README rewrite and the new skill README together so the repository always has one clear root landing page and one clear skill-local guide.
