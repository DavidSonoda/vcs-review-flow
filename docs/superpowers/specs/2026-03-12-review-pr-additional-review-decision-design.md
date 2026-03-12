# Review PR Additional Review Decision Design

## Goal

Ensure `review-pr` does not stop after collecting or validating remote comments. After the comment-handling phase, the skill must explicitly ask whether to run a full review of the MR/PR changeset for additional issues.

## Problem

The current `review-pr` flow allows the skill to conclude after unresolved-comment validation and confirmation. In practice, that leads to a truncated review session where the agent only reports on remote comments and never asks whether the user also wants a broader code review for issues not already mentioned in those comments.

## Requirements

- The skill must always reach an explicit additional-review decision point after the remote comment phase.
- This decision point is mandatory whether or not unresolved comments exist.
- This decision point is mandatory whether or not any approved comments remain valid after verification.
- The skill must use an explicit user question, not an implicit default.
- The question must offer exactly these choices:
  1. `Review full changeset for additional issues`
  2. `Do not do additional reviews`
  3. `Specify otherwise`
- The skill must not proceed directly from comment validation to change planning without handling this decision.
- If the user chooses full additional review, the skill must run a normal code review session over the prepared worktree and treat any new findings as separate from the remote-comment verification output.
- If the user declines additional review, the skill may continue with comment-scoped planning only.
- If the user specifies another instruction, the skill should follow that instruction if it is consistent with the rest of the workflow.

## Workflow Design

### Updated review flow

1. Resolve MR/PR target.
2. Fetch remote comments.
3. Ask whether to include code-review comments, if present.
4. Ask whether to include discussion comments, if present.
5. Inspect repo policy and prepare the worktree.
6. Validate approved remote comments when any categories were accepted.
7. Present the verification report when comment validation ran.
8. Ask the mandatory additional-review question with the three explicit options.
9. If the user chooses full additional review, run a full review of the changeset for new issues beyond the remote comments.
10. Produce the change plan using:
   - confirmed remote-comment issues, if any
   - any additional review findings, if the user requested full review

### No-comment case

If no remote comment categories exist, the skill still asks the mandatory additional-review question after worktree preparation and before change planning.

### Comment-only case

If the user selects `Do not do additional reviews`, the skill keeps the existing comment validation behavior and then produces a change plan limited to the in-scope remote feedback.

## Documentation Changes

- Update `skills/review-pr/SKILL.md` so the workflow order makes the additional-review decision mandatory.
- Update `skills/review-pr/README.md` flow description and mermaid chart to show the decision point before change planning.
- Update `skills/review-pr/docs/examples.md` so examples mention the mandatory three-option question.
- Extend the doc-oriented shell test to assert the new wording and ordering constraints.

## Testing Strategy

- Extend the existing documentation coverage test rather than introducing a separate test harness.
- Assert that all packaged docs mention:
  - the mandatory additional-review decision
  - the exact `Review full changeset for additional issues` option
  - the exact `Do not do additional reviews` option
  - the exact `Specify otherwise` option
- Assert that the skill doc no longer permits a path from comment verification directly to change planning without the decision point.

## Risks

- If the new prompt text is only added in one file, packaged skill docs can drift and the loophole will remain.
- If the prompt is described loosely rather than with exact wording, future agents may paraphrase it and omit one of the required choices.
- If the workflow order is not made explicit, an agent may still end the session after comment validation.
