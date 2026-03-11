#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

repo=.
platform=
number=
json_output=false

usage() {
  cat <<'USAGE'
Usage: fetch_review_comments.sh --repo <path> --number <id> [--platform <github|gitlab>] [--json]

Fetch MR/PR comments and normalize them into code-review comments and discussion comments.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo=$2
      shift 2
      ;;
    --platform)
      platform=$2
      shift 2
      ;;
    --number)
      number=$2
      shift 2
      ;;
    --json)
      json_output=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$number" ]] || die "--number is required"

repo=$(resolve_repo_root "$repo")
require_cmd jq

if [[ -z "$platform" ]]; then
  platform=$("$SCRIPT_DIR/detect_platform.sh" --repo "$repo")
fi

remote_url=$(origin_url "$repo")
repository=$(repository_slug_from_remote "$remote_url")

normalize_github_comments() {
  local review_comments=$1
  local discussion_comments=$2

  jq -cn \
    --arg platform "$platform" \
    --arg repository "$repository" \
    --arg number "$number" \
    --argjson review_comments "$review_comments" \
    --argjson discussion_comments "$discussion_comments" \
    '
      {
        platform: $platform,
        repository: $repository,
        number: $number,
        code_review_comments: {
          count: ($review_comments | length),
          items: ($review_comments | map({
            id: (.id | tostring),
            author: (.user.login // .user.name // "unknown"),
            body: (.body // ""),
            path: (.path // ""),
            line: (if .line == null then "" else (.line | tostring) end),
            url: (.html_url // ""),
            created_at: (.created_at // "")
          }))
        },
        discussion_comments: {
          count: ($discussion_comments | length),
          items: ($discussion_comments | map({
            id: (.id | tostring),
            author: (.user.login // .user.name // "unknown"),
            body: (.body // ""),
            url: (.html_url // ""),
            created_at: (.created_at // "")
          }))
        }
      }
    '
}

normalize_gitlab_comments() {
  local discussions=$1

  jq -cn \
    --arg platform "$platform" \
    --arg repository "$repository" \
    --arg number "$number" \
    --argjson discussions "$discussions" \
    '
      def active_notes:
        [
          $discussions[]
          | .notes[]?
          | select((.system // false) | not)
        ];

      def review_notes:
        [
          active_notes[]
          | select(
              (.position // null) != null
              or (.line_code // null) != null
            )
        ];

      def discussion_notes:
        [
          active_notes[]
          | select(
              (.position // null) == null
              and (.line_code // null) == null
            )
        ];

      {
        platform: $platform,
        repository: $repository,
        number: $number,
        code_review_comments: {
          count: (review_notes | length),
          items: (review_notes | map({
            id: (.id | tostring),
            author: (.author.username // .author.name // "unknown"),
            body: (.body // ""),
            path: (.position.new_path // .position.old_path // ""),
            line: (
              if (.position.new_line // null) != null then (.position.new_line | tostring)
              elif (.position.old_line // null) != null then (.position.old_line | tostring)
              else ""
              end
            ),
            url: (.url // .web_url // ""),
            created_at: (.created_at // "")
          }))
        },
        discussion_comments: {
          count: (discussion_notes | length),
          items: (discussion_notes | map({
            id: (.id | tostring),
            author: (.author.username // .author.name // "unknown"),
            body: (.body // ""),
            url: (.url // .web_url // ""),
            created_at: (.created_at // "")
          }))
        }
      }
    '
}

emit_kv() {
  local json=$1
  print_kv platform "$(printf '%s' "$json" | jq -r '.platform')"
  print_kv repository "$(printf '%s' "$json" | jq -r '.repository')"
  print_kv number "$(printf '%s' "$json" | jq -r '.number')"
  print_kv code_review_comment_count "$(printf '%s' "$json" | jq -r '.code_review_comments.count')"
  print_kv discussion_comment_count "$(printf '%s' "$json" | jq -r '.discussion_comments.count')"
}

cd "$repo"

case "$platform" in
  github)
    require_cmd gh
    review_comments=$(gh api "repos/$repository/pulls/$number/comments")
    discussion_comments=$(gh api "repos/$repository/issues/$number/comments")
    normalized=$(normalize_github_comments "$review_comments" "$discussion_comments")
    ;;
  gitlab)
    require_cmd glab
    encoded_repository=$(jq -nr --arg value "$repository" '$value | @uri')
    discussions=$(glab api "projects/$encoded_repository/merge_requests/$number/discussions" --paginate)
    normalized=$(normalize_gitlab_comments "$discussions")
    ;;
  *)
    die "unsupported platform: $platform"
    ;;
esac

if [[ "$json_output" == true ]]; then
  printf '%s\n' "$normalized"
else
  emit_kv "$normalized"
fi
