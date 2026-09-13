#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT_DIR/git/.local/bin/xdega-bot-pr"
WRAPPER="/Users/liam/Development/vantorix/scripts/open-pr.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local expected="$1"
  local file="$2"
  grep -F -- "$expected" "$file" >/dev/null || fail "$file does not contain: $expected"
}

run_expect_failure() {
  local expected="$1"
  shift
  if "$@" >"$OUTPUT_FILE" 2>&1; then
    fail "command unexpectedly succeeded: $*"
  fi
  assert_contains "$expected" "$OUTPUT_FILE"
}

run_in_repo_expect_failure() {
  local expected="$1"
  shift
  if (cd "$TEST_REPO" && "$@") >"$OUTPUT_FILE" 2>&1; then
    fail "command unexpectedly succeeded in test repository: $*"
  fi
  assert_contains "$expected" "$OUTPUT_FILE"
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/xdega-bot-helper-test.XXXXXX")"
OUTPUT_FILE="$TMP_ROOT/output"
ORIGINAL_HELPER_MODE="$(stat -f '%OLp' "$HELPER")"
cleanup() {
  chmod "$ORIGINAL_HELPER_MODE" "$HELPER" 2>/dev/null || true
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

[[ -x "$HELPER" ]] || fail "$HELPER must be executable"
[[ "$(head -1 "$HELPER")" == '#!/bin/bash' ]] || fail "helper must use an absolute interpreter"
bash -n "$HELPER"

assert_contains 'readonly KEYCHAIN_SERVICE="vantorix-github-app-private-key"' "$HELPER"
assert_contains '{repositories: [$repository], permissions: {contents: "write", pull_requests: "write"}}' "$HELPER"
assert_contains 'select(.repositories | length == 1)' "$HELPER"
assert_contains 'GIT_CONFIG_GLOBAL=/dev/null' "$HELPER"
assert_contains 'GH_CONFIG_DIR="$GH_CONFIG_DIR"' "$HELPER"
assert_contains 'git -c core.hooksPath=/dev/null' "$HELPER"
if grep -F 'git add -A' "$HELPER" >/dev/null; then
  fail "helper must not stage the entire worktree"
fi

run_expect_failure 'error: PR_TITLE is required' "$HELPER"

TEST_REPO="$TMP_ROOT/repository"
mkdir "$TEST_REPO"
git -C "$TEST_REPO" init -q -b feature/test
git -C "$TEST_REPO" config user.name Test
git -C "$TEST_REPO" config user.email test@example.com
touch "$TEST_REPO/tracked"
git -C "$TEST_REPO" add tracked
git -C "$TEST_REPO" commit -q -m initial
git -C "$TEST_REPO" remote add origin https://github.com/xdega/example.git
printf 'body\n' >"$TMP_ROOT/body.md"

printf 'untracked\n' >"$TEST_REPO/untracked"
run_in_repo_expect_failure 'worktree has unstaged changes' \
  env PR_TITLE=Test PR_BODY_FILE="$TMP_ROOT/body.md" \
  "$HELPER" feature/test
rm "$TEST_REPO/untracked"

printf 'changed\n' >"$TEST_REPO/tracked"
git -C "$TEST_REPO" add tracked
run_in_repo_expect_failure 'index has staged changes; provide a commit message' \
  env PR_TITLE=Test PR_BODY_FILE="$TMP_ROOT/body.md" \
  "$HELPER" feature/test

if [[ -f "$WRAPPER" ]]; then
  bash -n "$WRAPPER"
  assert_contains 'readonly HELPER="/Users/liam/.local/bin/xdega-bot-pr"' "$WRAPPER"
  assert_contains '"$HELPER" -ef "$EXPECTED_HELPER"' "$WRAPPER"
  assert_contains 'exec /bin/bash "$HELPER" "$@"' "$WRAPPER"

  mkdir "$TMP_ROOT/fake-bin"
  cat >"$TMP_ROOT/fake-bin/xdega-bot-pr" <<EOF
#!/bin/bash
touch "$TMP_ROOT/path-hijacked"
EOF
  chmod +x "$TMP_ROOT/fake-bin/xdega-bot-pr"
  run_expect_failure 'error: PR_TITLE is required' \
    env PATH="$TMP_ROOT/fake-bin:/usr/bin:/bin" "$WRAPPER"
  [[ ! -e "$TMP_ROOT/path-hijacked" ]] || fail "wrapper executed a PATH-injected helper"

  chmod g+w "$HELPER"
  run_expect_failure 'trusted helper must be owned by the current user and not group/world writable' \
    "$WRAPPER"
  chmod "$ORIGINAL_HELPER_MODE" "$HELPER"
fi

echo "PASS: GitHub App helper guardrails"
