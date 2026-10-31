#!/usr/bin/env bash
# lint.sh -- run shellcheck and ruff over the repository's tracked scripts.
#
# Usage: scripts/lint.sh [--list | --self-test | -h]
#
# Files: every tracked file except symlinks. Shell scripts are *.sh, *.bash,
# *.qsub, *.pbs and *.sbatch files, plus any other file whose first line is a
# bash or sh shebang. Python files are *.py.
#
# - The shellcheck run fails on warning and error severity (-S warning); info
#   and style findings are not reported. Mark an intended finding with a
#   `disable=SCxxxx  # reason` directive comment on the line before it.
# - The ruff run uses the rule set pinned in ruff.toml.
#
# (No comment line in a shell script may start with the word "shellcheck"
# unless it is meant as a directive: shellcheck reads such a line as one.)
#
# Skipping: a tool that is not found is skipped with a SKIP line, so
# `make lint` and `make test` still pass where it is not installed. A project
# that has a tool but does not want it lists it in LINT_SKIP, such as
# LINT_SKIP="ruff". LINT_SHELLCHECK and LINT_RUFF name the commands to run
# (default: shellcheck and ruff on PATH).
#
#   --list       print the files each tool would check, and exit
#   --self-test  run the fixture test on a throwaway repository
#
# Exit status: 0 when every tool that ran found nothing, 1 on any finding,
# 2 on a usage error.

set -euo pipefail

usage() { sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'; }

LINT_SKIP="${LINT_SKIP:-}"
LINT_SHELLCHECK="${LINT_SHELLCHECK:-shellcheck}"
LINT_RUFF="${LINT_RUFF:-ruff}"

shell_files=()
python_files=()

collect_files() {
    local file first
    while IFS= read -r -d '' file; do
        [ -L "$file" ] && continue
        [ -f "$file" ] || continue
        case "$file" in
            *.py) python_files+=("$file"); continue ;;
            *.sh|*.bash|*.qsub|*.pbs|*.sbatch) ;;
            *)
                first=""
                IFS= read -r first < "$file" || true
                case "$first" in
                    '#!'*[/\ ]bash|'#!'*[/\ ]bash[\ ]*|'#!'*[/\ ]sh|'#!'*[/\ ]sh[\ ]*) ;;
                    *) continue ;;
                esac
                ;;
        esac
        shell_files+=("$file")
    done < <(git ls-files -z)
}

skipped() { case " $LINT_SKIP " in *" $1 "*) return 0 ;; esac; return 1; }

lint() {
    local status=0

    if skipped shellcheck; then
        echo "SKIP: shellcheck (listed in LINT_SKIP)"
    elif ! command -v "$LINT_SHELLCHECK" >/dev/null 2>&1; then
        echo "SKIP: shellcheck is not installed (set LINT_SHELLCHECK, or LINT_SKIP=shellcheck to silence this)"
    else
        printf 'Running %s on %d shell scripts\n' \
            "$("$LINT_SHELLCHECK" --version | sed -n 's/^version: /shellcheck /p')" "${#shell_files[@]}"
        if [ "${#shell_files[@]}" = 0 ] || "$LINT_SHELLCHECK" -x -S warning "${shell_files[@]}"; then
            echo "OK: shellcheck found no warnings or errors"
        else
            status=1
        fi
    fi

    if skipped ruff; then
        echo "SKIP: ruff (listed in LINT_SKIP)"
    elif ! command -v "$LINT_RUFF" >/dev/null 2>&1; then
        echo "SKIP: ruff is not installed (set LINT_RUFF, or LINT_SKIP=ruff to silence this)"
    else
        printf 'Running %s on %d Python files\n' "$("$LINT_RUFF" --version)" "${#python_files[@]}"
        if [ "${#python_files[@]}" = 0 ] || "$LINT_RUFF" check --no-cache --quiet "${python_files[@]}"; then
            echo "OK: ruff found no problems"
        else
            status=1
        fi
    fi

    return "$status"
}

self_test() {
    local script tmp out rc fails=0 have_sc=0 have_ruff=0
    script="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/lint_test.XXXXXX")"
    trap 'rm -rf "$tmp"' RETURN
    export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid
    export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid
    export GIT_CONFIG_NOSYSTEM=1

    ok() { echo "  ok    $1"; }
    fail() { echo "  FAIL  $1"; fails=$((fails + 1)); }
    check() { if [ "$2" = 0 ]; then ok "$1"; else fail "$1"; fi; }
    run() { (cd "$tmp/work" && HOME="$tmp" bash "$script" "$@"); }
    has() { grep -qF -- "$1" <<<"$out"; }
    command -v "$LINT_SHELLCHECK" >/dev/null 2>&1 && have_sc=1
    command -v "$LINT_RUFF" >/dev/null 2>&1 && have_ruff=1

    local root
    root="$(cd "$(dirname "$script")/.." && pwd)"
    (
        set -e
        mkdir "$tmp/work" && cd "$tmp/work"
        git init -q .
        cp "$root/ruff.toml" .
        mkdir bin
        printf '#!/usr/bin/env bash\nset -euo pipefail\necho "ok: $#"\n' > good.sh
        printf '#!/bin/sh\necho "ok: $#"\n' > bin/tool
        printf '#!/usr/bin/env python3\necho not shell\n' > bin/pytool
        printf 'plain text\n' > notes.txt
        ln -s ../good.sh bin/good-alias
        printf 'import sys\n\nprint(sys.argv)\n' > good.py
        git add -A && git commit -qm clean
    ) || { echo "FAIL: could not build the fixture"; return 1; }

    echo "file selection:"
    out="$(run --list 2>&1)"; rc=$?
    check "exits 0" "$rc"
    if [ "$(grep -c '^shell: ' <<<"$out")" = 2 ] && has "shell: good.sh" && has "shell: bin/tool"; then
        ok "shell: *.sh and a sh shebang, not a python shebang, a symlink or text"
    else
        fail "shell: *.sh and a sh shebang, not a python shebang, a symlink or text"
    fi
    if [ "$(grep -c '^python: ' <<<"$out")" = 1 ] && has "python: good.py"; then ok "python: *.py"; else fail "python: *.py"; fi

    echo "clean files:"
    out="$(run 2>&1)"; rc=$?
    check "exits 0" "$rc"
    if [ "$have_sc" = 1 ]; then has "OK: shellcheck"; check "shellcheck runs and passes" $?; fi
    if [ "$have_ruff" = 1 ]; then has "OK: ruff"; check "ruff runs and passes" $?; fi

    echo "findings:"
    printf '#!/bin/bash\ncd "$1"\nls\n' > "$tmp/work/bin/bad-tool"
    printf 'import os\nl = 1\n' > "$tmp/work/bad.py"
    git -C "$tmp/work" add -A
    out="$(run 2>&1)"; rc=$?
    if [ "$have_sc" = 1 ] || [ "$have_ruff" = 1 ]; then
        if [ "$rc" = 1 ]; then ok "exits 1"; else fail "exits 1"; fi
    else
        echo "  skip  neither tool is installed, so no finding can be reported"
    fi
    if [ "$have_sc" = 1 ]; then has "SC2164"; check "shellcheck reports a bare cd in a shebang-only script" $?; fi
    if [ "$have_ruff" = 1 ]; then
        has "F401"; check "ruff reports an unused import" $?
        has "E741"; check "ruff reports a variable named l" $?
    fi

    echo "skipping:"
    out="$(LINT_SKIP="shellcheck ruff" run 2>&1)"; rc=$?
    check "LINT_SKIP: exits 0 despite findings" "$rc"
    if has "SKIP: shellcheck (listed in LINT_SKIP)" && has "SKIP: ruff (listed in LINT_SKIP)"; then
        ok "LINT_SKIP: both tools print a SKIP line"
    else
        fail "LINT_SKIP: both tools print a SKIP line"
    fi
    out="$(LINT_SHELLCHECK=lint-test-no-such-tool LINT_RUFF=lint-test-no-such-tool run 2>&1)"; rc=$?
    check "missing tools: exits 0 despite findings" "$rc"
    if has "SKIP: shellcheck is not installed" && has "SKIP: ruff is not installed"; then
        ok "missing tools: both print a SKIP line"
    else
        fail "missing tools: both print a SKIP line"
    fi

    echo "usage:"
    run --bogus >/dev/null 2>&1; rc=$?
    if [ "$rc" = 2 ]; then ok "an unknown option exits 2"; else fail "an unknown option exits 2"; fi

    [ "$have_sc" = 1 ] || echo "NOTE: shellcheck is not installed; its checks were not run."
    [ "$have_ruff" = 1 ] || echo "NOTE: ruff is not installed; its checks were not run."
    if [ "$fails" -gt 0 ]; then echo "RESULT: FAIL - $fails check(s) failed."; return 1; fi
    echo "RESULT: OK - lint.sh self-test passed."
}

case "${1:-}" in
    --self-test) set +e; self_test; exit $? ;;
    -h|--help) usage; exit 0 ;;
    --list) ;;
    "") ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
esac

cd "$(git rev-parse --show-toplevel)"
collect_files

if [ "${1:-}" = --list ]; then
    for f in ${shell_files[@]+"${shell_files[@]}"}; do echo "shell: $f"; done
    for f in ${python_files[@]+"${python_files[@]}"}; do echo "python: $f"; done
    exit 0
fi

lint
