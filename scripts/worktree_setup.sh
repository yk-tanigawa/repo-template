#!/usr/bin/env bash
# worktree_setup.sh -- copy .env.local from the main worktree into a new linked
# git worktree, so `make setup` can link _data/ and _repos/ there.
# See docs/local-development.md ("Working in a Git Worktree").
#
# Usage:
#   scripts/worktree_setup.sh              copy .env.local into this worktree
#   scripts/worktree_setup.sh --hint       print a one-line hint when this is a
#                                          linked worktree without .env.local
#   scripts/worktree_setup.sh --self-test  run the fixture test
#
# `make worktree-setup` runs this script, then `make setup`.
#
# The main worktree is the first entry of `git worktree list --porcelain`.
# An existing .env.local is never overwritten, and the file's contents are
# never printed. In the main worktree there is nothing to copy, and the script
# says so and exits 0. When the main worktree has no .env.local either, the
# script points to .env.local.example and exits 0, so `make setup` then skips
# the links it cannot make.
#
# Exit status: 0 on success or nothing to do, 1 on an error, 2 on a usage error.

set -euo pipefail

usage() { sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; }

# Physical path of this checkout's top level.
current_top() { (cd "$(git rev-parse --show-toplevel)" && pwd -P); }

# Physical path of the main worktree (the first `worktree` line).
main_top() {
    local path
    path="$(git worktree list --porcelain | sed -n '1s/^worktree //p')"
    [ -n "$path" ] || return 1
    (cd "$path" && pwd -P)
}

copy_env() {
    local here main
    here="$(current_top)" || { echo "ERROR: not inside a git checkout." >&2; return 1; }
    main="$(main_top)" || { echo "ERROR: could not find the main worktree (git worktree list failed)." >&2; return 1; }

    if [ "$here" = "$main" ]; then
        echo "This is the main worktree; nothing to copy."
        return 0
    fi
    echo "Linked worktree: $here"
    echo "Main worktree:   $main"
    if [ -e "$here/.env.local" ]; then
        echo "Keeping the existing .env.local in this worktree (not overwritten)."
        return 0
    fi
    if [ ! -f "$main/.env.local" ]; then
        echo "The main worktree has no .env.local; nothing to copy."
        echo "Copy .env.local.example to .env.local in the main worktree, fill it in, and run 'make worktree-setup' again."
        return 0
    fi
    cp -p "$main/.env.local" "$here/.env.local"
    echo "Copied .env.local from the main worktree."
}

hint() {
    local here main
    here="$(current_top 2>/dev/null)" || return 0
    main="$(main_top 2>/dev/null)" || return 0
    if [ "$here" != "$main" ] && [ ! -e "$here/.env.local" ]; then
        echo "  Hint: this is a linked git worktree without .env.local; run 'make worktree-setup'."
    fi
}

self_test() {
    local script tmp out fails=0 ver
    ver="$(git --version | awk '{ print $3 }')"
    if ! printf '%s\n' "$ver" | awk -F. '{ exit !($1 > 2 || ($1 == 2 && $2 >= 17)) }'; then
        echo "SKIP: the worktree_setup.sh self-test needs git 2.17 or newer; $(command -v git) is $ver"
        return 0
    fi
    script="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/worktree_setup_test.XXXXXX")"
    trap 'rm -rf "$tmp"' RETURN
    export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid
    export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid
    export GIT_CONFIG_NOSYSTEM=1 HOME="$tmp"

    expect() {  # expect <description> <pattern> (grep -E against $out)
        if grep -qE -- "$2" <<<"$out"; then echo "  ok    $1"
        else echo "  FAIL  $1 (no match for: $2)"; fails=$((fails + 1)); fi
    }
    expect_not() {  # expect_not <description> <pattern>
        if grep -qE -- "$2" <<<"$out"; then echo "  FAIL  $1 (unexpected match: $2)"; fails=$((fails + 1))
        else echo "  ok    $1"; fi
    }
    check() {  # check <description> <command...>
        local desc="$1"; shift
        if "$@"; then echo "  ok    $desc"; else echo "  FAIL  $desc"; fails=$((fails + 1)); fi
    }

    (
        set -e
        cd "$tmp"
        git init -q main && cd main
        printf '.env.local\n' > .gitignore
        git add .gitignore && git commit -qm init
        printf 'PROJECT_EXTERNAL_DATA_ROOT=/fixture/SECRET_MARKER\n' > .env.local
        git worktree add -q -b wt1 ../wt1
        git worktree add -q -b wt2 ../wt2
        mkdir -p ../wt1/sub
    ) || { echo "FAIL: could not build the fixture"; return 1; }

    echo "linked worktree without .env.local:"
    out="$(cd "$tmp/wt1" && bash "$script" --hint 2>&1)"
    expect "--hint points to make worktree-setup" "run 'make worktree-setup'"
    out="$(cd "$tmp/wt1/sub" && bash "$script" 2>&1)"
    expect "copy is reported" 'Copied \.env\.local from the main worktree'
    expect_not "contents are not printed" 'SECRET_MARKER'
    check ".env.local is identical to the main worktree's" cmp -s "$tmp/main/.env.local" "$tmp/wt1/.env.local"
    out="$(cd "$tmp/wt1" && bash "$script" --hint 2>&1)"
    check "--hint is silent once .env.local exists" test -z "$out"

    echo "linked worktree with its own .env.local:"
    printf 'LOCAL_ONLY=1\n' > "$tmp/wt1/.env.local"
    out="$(cd "$tmp/wt1" && bash "$script" 2>&1)"
    expect "existing file is kept" 'Keeping the existing \.env\.local'
    check "existing file is not overwritten" grep -q '^LOCAL_ONLY=1$' "$tmp/wt1/.env.local"

    echo "main worktree:"
    out="$(cd "$tmp/main" && bash "$script" 2>&1)"
    expect "nothing to copy in the main worktree" 'This is the main worktree; nothing to copy'
    out="$(cd "$tmp/main" && bash "$script" --hint 2>&1)"
    check "--hint is silent in the main worktree" test -z "$out"

    echo "main worktree without .env.local:"
    rm "$tmp/main/.env.local"
    out="$(cd "$tmp/wt2" && bash "$script" 2>&1)" || { echo "  FAIL  script exited non-zero"; fails=$((fails + 1)); }
    expect "missing source is reported" 'The main worktree has no \.env\.local'
    check "no .env.local is created" test ! -e "$tmp/wt2/.env.local"

    if [ "$fails" -gt 0 ]; then echo "RESULT: FAIL - $fails check(s) failed."; return 1; fi
    echo "RESULT: OK - worktree_setup.sh self-test passed."
}

case "${1:-}" in
    "") copy_env ;;
    --hint) hint ;;
    --self-test) self_test ;;
    -h|--help) usage ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
esac
