#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT="$ROOT_DIR/scripts/fetch_review_comments.sh"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

assert_eq() {
  local expected=$1
  local actual=$2
  local message=$3
  if [[ "$expected" != "$actual" ]]; then
    printf 'assertion failed: %s\nexpected: %s\nactual:   %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

make_fake_bin() {
  local fake_bin=$1
  mkdir -p "$fake_bin"

  cat >"$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1-}" == "-C" ]]; then
  repo=$2
  shift 2
else
  repo=$(pwd)
fi

case "${1-} ${2-} ${3-}" in
  "rev-parse --show-toplevel " )
    printf '%s\n' "$repo"
    ;;
  "remote get-url origin" )
    printf 'git@github.com:acme/widgets.git\n'
    ;;
  * )
    printf 'unexpected git invocation: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "$fake_bin/git"

  cat >"$fake_bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1-}" != "api" ]]; then
  printf 'unexpected gh invocation: %s\n' "$*" >&2
  exit 1
fi

endpoint=${2-}
case "$endpoint" in
  repos/acme/widgets/pulls/77/comments)
    cat <<'JSON'
[
  {
    "id": 101,
    "user": {"login": "reviewer"},
    "body": "Rename this helper",
    "path": "src/app.ts",
    "line": 42,
    "html_url": "https://github.com/acme/widgets/pull/77#discussion_r101",
    "created_at": "2026-03-11T08:00:00Z"
  }
]
JSON
    ;;
  repos/acme/widgets/issues/77/comments)
    cat <<'JSON'
[
  {
    "id": 202,
    "user": {"login": "maintainer"},
    "body": "Please update the release notes too.",
    "html_url": "https://github.com/acme/widgets/pull/77#issuecomment-202",
    "created_at": "2026-03-11T09:00:00Z"
  }
]
JSON
    ;;
  *)
    printf 'unexpected gh endpoint: %s\n' "$endpoint" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "$fake_bin/gh"

  cat >"$fake_bin/glab" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1-}" != "api" ]]; then
  printf 'unexpected glab invocation: %s\n' "$*" >&2
  exit 1
fi

endpoint=${2-}
case "$endpoint" in
  projects/acme%2Fwidgets/merge_requests/55/discussions)
    cat <<'JSON'
[
  {
    "id": "review-thread",
    "individual_note": false,
    "notes": [
      {
        "id": 301,
        "system": false,
        "body": "Please rename this variable.",
        "created_at": "2026-03-11T10:00:00Z",
        "author": {"username": "gitlab-reviewer"},
        "position": {
          "new_path": "src/service.kt",
          "new_line": 18
        },
        "resolvable": true,
        "url": "https://gitlab.example.com/acme/widgets/-/merge_requests/55#note_301"
      }
    ]
  },
  {
    "id": "discussion-thread",
    "individual_note": false,
    "notes": [
      {
        "id": 302,
        "system": false,
        "body": "Can we summarize this change in the MR description?",
        "created_at": "2026-03-11T11:00:00Z",
        "author": {"username": "gitlab-maintainer"},
        "resolvable": false,
        "url": "https://gitlab.example.com/acme/widgets/-/merge_requests/55#note_302"
      }
    ]
  }
]
JSON
    ;;
  *)
    printf 'unexpected glab endpoint: %s\n' "$endpoint" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "$fake_bin/glab"
}

test_github_json_split() {
  local fake_bin="$TMP_DIR/fake-bin"
  make_fake_bin "$fake_bin"

  local output
  output=$(PATH="$fake_bin:$PATH" bash "$SCRIPT" --repo "$ROOT_DIR" --platform github --number 77 --json)

  assert_eq "1" "$(printf '%s' "$output" | jq -r '.code_review_comments.count')" "github code review comment count"
  assert_eq "1" "$(printf '%s' "$output" | jq -r '.discussion_comments.count')" "github discussion comment count"
  assert_eq "src/app.ts" "$(printf '%s' "$output" | jq -r '.code_review_comments.items[0].path')" "github review comment path"
  assert_eq "maintainer" "$(printf '%s' "$output" | jq -r '.discussion_comments.items[0].author')" "github discussion author"
}

test_gitlab_json_split() {
  local fake_bin="$TMP_DIR/fake-bin"
  make_fake_bin "$fake_bin"

  local output
  output=$(PATH="$fake_bin:$PATH" bash "$SCRIPT" --repo "$ROOT_DIR" --platform gitlab --number 55 --json)

  assert_eq "1" "$(printf '%s' "$output" | jq -r '.code_review_comments.count')" "gitlab code review comment count"
  assert_eq "1" "$(printf '%s' "$output" | jq -r '.discussion_comments.count')" "gitlab discussion comment count"
  assert_eq "src/service.kt" "$(printf '%s' "$output" | jq -r '.code_review_comments.items[0].path')" "gitlab review comment path"
  assert_eq "gitlab-maintainer" "$(printf '%s' "$output" | jq -r '.discussion_comments.items[0].author')" "gitlab discussion author"
}

test_docs_cover_two_step_scope_flow() {
  grep -q 'fetch_review_comments.sh' "$ROOT_DIR/SKILL.md"
  grep -q 'code-review comments' "$ROOT_DIR/SKILL.md"
  grep -q 'discussion comments' "$ROOT_DIR/SKILL.md"
  grep -qi 'ask the user whether to include code-review comments in scope' "$ROOT_DIR/README.md"
  grep -qi 'ask the user whether to include discussion comments in scope' "$ROOT_DIR/docs/examples.md"
  ! rg -n '/Users/brainco' "$ROOT_DIR/README.md" >/dev/null
}

test_github_json_split
test_gitlab_json_split
test_docs_cover_two_step_scope_flow

printf 'PASS\n'
