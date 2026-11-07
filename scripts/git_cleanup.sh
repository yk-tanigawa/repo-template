#!/usr/bin/env bash
# git_cleanup.sh — remove local git worktrees and branches whose work is already
# in the base branch (origin/main by default). A dry run by default: it prints
# what it would do and changes nothing. See docs/local-development.md
# ("Git Housekeeping").
#
# Usage:
#   scripts/git_cleanup.sh [REPO]                      dry run (REPO defaults to .)
#   scripts/git_cleanup.sh [REPO] --execute            delete what the dry run lists under DELETE
#   scripts/git_cleanup.sh [REPO] --execute --include-unmerged
#                                                      also delete the branches listed as unmerged
#   scripts/git_cleanup.sh --base REF ...              compare with REF, a remote-tracking
#                                                      branch such as origin/master
#   scripts/git_cleanup.sh --no-gh ...                 do not look up open PRs
#   scripts/git_cleanup.sh --self-test                 run the fixture test
#
# The base is the first of: --base REF; the GIT_CLEANUP_BASE environment
# variable; origin/main; the branch that origin/HEAD points to (the remote's
# default branch). It must be a remote-tracking branch, and the script stops if
# none of these resolves. The first lines of the output name the base used.
# Below, "main" means the base's branch name, such as master for origin/master.
#
# A worktree or branch is deleted only when every commit on it is in the base,
# as an ancestor or as the same change applied again (git cherry), so a branch
# that was rebased before merging counts as merged. A squash merge does not: its
# branch is listed as unmerged. Never touched: the base branch (main), the main
# checkout and the checkout the script runs from, with their branches, branches
# with an open PR, worktrees with uncommitted changes, and locked worktrees.
# Remote branches are only listed, never deleted.
#
# Before --execute deletes anything, every branch name and tip SHA is written to
# <git dir>/cleanup-backups/, so `git branch <name> <sha>` restores a branch.
#
# Open PRs are looked up with the GitHub CLI (gh) on PATH. Without gh, or when
# gh is not logged in, the open-PR guard is off and the script says so.

set -euo pipefail

base=""         # the ref branches are compared with, such as origin/main; set by resolve_base
remote=""       # its remote, such as origin
main_branch=""  # its branch name on that remote, such as main; the local branch of this name is kept

# The comment block at the top of this file, without the shebang and the "# ".
usage() { awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"; }

# Set base, remote and main_branch. $1 is the --base value and $2 the
# GIT_CLEANUP_BASE value; either may be empty. The base must be a remote-tracking
# branch, so that "merged" means merged on the remote.
resolve_base() {
    local want how full
    if [ -n "$1" ]; then
        want="$1" how="from --base"
    elif [ -n "$2" ]; then
        want="$2" how="from GIT_CLEANUP_BASE"
    elif git rev-parse -q --verify refs/remotes/origin/main >/dev/null; then
        want=origin/main how="default"
    elif full="$(git symbolic-ref -q refs/remotes/origin/HEAD)"; then
        want="${full#refs/remotes/}" how="origin/main not found; from origin/HEAD"
    else
        echo "ERROR: origin/main not found and origin/HEAD is not set." >&2
        echo "Name the default branch with --base, for example --base origin/master." >&2
        return 1
    fi
    if ! git rev-parse -q --verify "$want^{commit}" >/dev/null; then
        echo "ERROR: base $want ($how) not found" >&2
        return 1
    fi
    full="$(git rev-parse --symbolic-full-name "$want" 2>/dev/null || true)"
    case "$full" in
        refs/remotes/*/*) ;;
        *)
            echo "ERROR: base $want ($how) is not a remote-tracking branch; use, for example, origin/master" >&2
            return 1
            ;;
    esac
    base="${full#refs/remotes/}"
    remote="${base%%/*}"
    main_branch="${base#*/}"
    echo "base: $base ($how)"
}

# 0 when every commit on $1 that is not in $base has an identical change in $base.
in_main() {
    git merge-base --is-ancestor "$1" "$base" && return 0
    ! git cherry "$base" "$1" | grep -q '^+'
}

contains_line() { grep -qxF -- "$2" <<<"$1"; }

cleanup() {
    local repo="$1" execute="$2" include_unmerged="$3" use_gh="$4" want_base="$5"
    local top current open_prs="" gh_ok=0 fetch_remote=origin

    cd "$repo"
    top="$(git rev-parse --show-toplevel)"
    cd "$top"
    echo "repo: $top"
    # Fetch the remote that the requested base names (origin otherwise) before
    # resolving the base, so that a fresh origin/HEAD or origin/main is seen.
    local requested="${want_base:-${GIT_CLEANUP_BASE:-}}"
    if [ -n "$requested" ] && contains_line "$(git remote)" "${requested%%/*}"; then
        fetch_remote="${requested%%/*}"
    fi
    git fetch -q --prune "$fetch_remote"
    resolve_base "$want_base" "${GIT_CLEANUP_BASE:-}" || return 1
    current="$(git symbolic-ref -q --short HEAD || true)"

    if [ "$use_gh" = 1 ]; then
        if command -v gh >/dev/null 2>&1 && open_prs="$(gh pr list --state open --limit 500 --json headRefName -q '.[].headRefName' 2>/dev/null)"; then
            gh_ok=1
        else
            open_prs=""
            echo "note: could not list open PRs with gh (is gh on PATH, and is 'gh auth status' OK?)."
            echo "      Branches are still deleted only when all their commits are in $base."
        fi
    fi

    # ---- worktrees ----
    local -a wt_delete=()
    local kept_wt_branches="" path="" head="" branch="" locked=0 line wt_list
    # Stop rather than miss a checked-out branch: git older than 2.17 cannot
    # list worktrees in the porcelain format this relies on.
    if ! wt_list="$(git worktree list --porcelain 2>&1)"; then
        echo "ERROR: 'git worktree list' failed with $(git --version):" >&2
        echo "$wt_list" >&2
        echo "Use git 2.17 or newer." >&2
        return 1
    fi
    echo
    echo "== Worktrees"
    local main_wt=""
    flush_wt() {
        [ -n "$path" ] || return 0
        # git lists the main working tree first. Keep it and the checkout this
        # runs from, with their branches, whichever worktree the script is run
        # from.
        [ -n "$main_wt" ] || main_wt="$path"
        if [ "$path" = "$main_wt" ] || [ "$path" = "$top" ]; then
            echo "  KEEP    $path  [${branch:-(detached)}] main checkout or the current one"
            kept_wt_branches="$kept_wt_branches"$'\n'"$branch"
        else
            local name="${branch:-(detached)}" dirty
            if [ ! -d "$path" ]; then
                echo "  DELETE  $path  [$name] directory is missing"
                wt_delete+=("$path")
            elif [ "$locked" = 1 ]; then
                echo "  KEEP    $path  [$name] locked"
                kept_wt_branches="$kept_wt_branches"$'\n'"$branch"
            else
                dirty="$(git -C "$path" status --porcelain | wc -l | tr -d ' ')"
                if [ "$dirty" != 0 ]; then
                    echo "  KEEP    $path  [$name] $dirty uncommitted change(s); review by hand"
                    kept_wt_branches="$kept_wt_branches"$'\n'"$branch"
                elif [ -n "$branch" ] && contains_line "$open_prs" "$branch"; then
                    echo "  KEEP    $path  [$name] open PR"
                    kept_wt_branches="$kept_wt_branches"$'\n'"$branch"
                elif in_main "$head"; then
                    echo "  DELETE  $path  [$name] clean, all commits in $base"
                    wt_delete+=("$path")
                else
                    echo "  KEEP    $path  [$name] clean, but has commits not in $base"
                    kept_wt_branches="$kept_wt_branches"$'\n'"$branch"
                fi
            fi
        fi
        path="" head="" branch="" locked=0
    }
    while IFS= read -r line; do
        case "$line" in
            "worktree "*) flush_wt; path="${line#worktree }" ;;
            "HEAD "*) head="${line#HEAD }" ;;
            "branch "*) branch="${line#branch refs/heads/}" ;;
            locked*) locked=1 ;;
        esac
    done <<< "$wt_list"
    flush_wt

    # ---- local branches ----
    local -a br_delete=() br_unmerged=()
    local b n
    echo
    echo "== Local branches"
    while IFS= read -r b; do
        if [ "$b" = "$main_branch" ] || [ "$b" = "$current" ]; then
            echo "  KEEP    $b  $main_branch or the current branch"
        elif contains_line "$open_prs" "$b"; then
            echo "  KEEP    $b  open PR"
        elif contains_line "$kept_wt_branches" "$b"; then
            echo "  KEEP    $b  checked out in a kept worktree"
        elif in_main "$b"; then
            echo "  DELETE  $b  all commits in $base"
            br_delete+=("$b")
        else
            n="$(git cherry "$base" "$b" | grep -c '^+' || true)"
            echo "  KEEP    $b  $n commit(s) not in $base (unmerged):"
            git cherry -v "$base" "$b" | grep '^+' | cut -c3-100 | sed 's/^/            /'
            br_unmerged+=("$b")
        fi
    done < <(git for-each-ref --format='%(refname:short)' refs/heads)
    if [ "$include_unmerged" = 1 ] && [ "${#br_unmerged[@]}" -gt 0 ]; then
        br_delete+=("${br_unmerged[@]}")
    fi

    # ---- remote branches: listed only ----
    local remote_merged=""
    while IFS= read -r b; do
        b="${b#refs/remotes/"$remote"/}"
        if [ "$b" = HEAD ] || [ "$b" = "$main_branch" ]; then continue; fi
        contains_line "$open_prs" "$b" && continue
        if in_main "$remote/$b"; then remote_merged="$remote_merged $b"; fi
    done < <(git for-each-ref --format='%(refname)' "refs/remotes/$remote")
    echo
    echo "== Remote branches in $base (not deleted by this script)"
    if [ -n "$remote_merged" ]; then
        for b in $remote_merged; do echo "  $b"; done
        echo "  To delete them yourself:  git push $remote --delete$remote_merged"
    else
        echo "  none"
    fi

    echo
    echo "Summary: ${#wt_delete[@]} worktree(s) and ${#br_delete[@]} branch(es) to delete;" \
         "${#br_unmerged[@]} unmerged branch(es) $([ "$include_unmerged" = 1 ] && echo included || echo kept)."
    if [ "$gh_ok" != 1 ]; then echo "Open PRs were not checked."; fi
    if [ "$execute" != 1 ]; then
        echo "Dry run: nothing changed. Re-run with --execute to apply."
        return 0
    fi

    local backup_dir backup
    backup_dir="$(cd "$(git rev-parse --git-common-dir)" && pwd)/cleanup-backups"
    mkdir -p "$backup_dir"
    backup="$backup_dir/branches.$(date +%Y%m%d-%H%M%S).txt"
    git for-each-ref --format='%(refname:short) %(objectname)' refs/heads > "$backup"
    echo "Branch tips saved to $backup"

    local p failed=0
    if [ "${#wt_delete[@]}" -gt 0 ]; then
        for p in "${wt_delete[@]}"; do
            if [ ! -d "$p" ]; then continue; fi
            if git worktree remove "$p"; then echo "removed worktree $p"; else failed=1; fi
        done
    fi
    git worktree prune
    if [ "${#br_delete[@]}" -gt 0 ]; then
        for b in "${br_delete[@]}"; do
            if git branch -D -q "$b"; then echo "deleted branch $b"; else failed=1; fi
        done
    fi
    if [ "$failed" = 1 ]; then echo "Some deletions failed; see above." >&2; return 1; fi
    echo "Done."
}

self_test() {
    local script tmp out fails=0 ver
    # The fixture needs `git worktree` (git 2.17+). Skip on older git with the
    # fix rather than fail halfway through building the fixture, so `make test`
    # stays usable.
    ver="$(git --version | awk '{ print $3 }')"
    if ! printf '%s\n' "$ver" | awk -F. '{ exit !($1 > 2 || ($1 == 2 && $2 >= 17)) }'; then
        echo "SKIP: the git_cleanup.sh self-test needs git 2.17 or newer; $(command -v git) is $ver"
        return 0
    fi
    script="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/git_cleanup_test.XXXXXX")"
    trap 'rm -rf "$tmp"' RETURN
    export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid
    export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid
    export GIT_CONFIG_NOSYSTEM=1 HOME="$tmp"
    unset GIT_CLEANUP_BASE

    expect() {  # expect <description> <pattern> (grep -E against $out)
        if grep -qE -- "$2" <<<"$out"; then echo "  ok    $1"
        else echo "  FAIL  $1 (no match for: $2)"; fails=$((fails + 1)); fi
    }
    expect_ref() {  # expect_ref <present|absent> <branch> [repo, default $tmp/work]
        if git -C "${3:-$tmp/work}" rev-parse -q --verify "refs/heads/$2" >/dev/null; then
            [ "$1" = present ] && echo "  ok    $2 kept" || { echo "  FAIL  $2 should be deleted"; fails=$((fails + 1)); }
        else
            [ "$1" = absent ] && echo "  ok    $2 deleted" || { echo "  FAIL  $2 should be kept"; fails=$((fails + 1)); }
        fi
    }

    (
        set -e
        cd "$tmp"
        git init -q --bare origin.git
        git init -q work && cd work
        git checkout -q -b main
        echo a > a.txt && git add a.txt && git commit -qm A
        git remote add origin ../origin.git && git push -q origin main
        # merged: merged with a merge commit
        git checkout -q -b merged && echo b > b.txt && git add b.txt && git commit -qm B
        git push -q origin merged
        git checkout -q main && git merge -q --no-ff --no-edit merged
        # rebased: the same change reached main as a different commit
        git checkout -q -b rebased main~0 && echo c > c.txt && git add c.txt && git commit -qm C
        git checkout -q main && echo e > e.txt && git add e.txt && git commit -qm E
        git cherry-pick rebased >/dev/null
        # wt-merged / wt-dirty: merged branches checked out in worktrees
        git branch wt-merged main && git branch wt-dirty main
        git push -q origin main
        # unmerged: a commit main does not have
        git checkout -q -b unmerged && echo d > d.txt && git add d.txt && git commit -qm D
        git checkout -q main
        git worktree add -q ../wt-clean wt-merged
        git worktree add -q ../wt-dirty wt-dirty
        echo edit >> ../wt-dirty/a.txt
    ) || { echo "FAIL: could not build the fixture"; return 1; }

    echo "dry run:"
    out="$(bash "$script" --no-gh "$tmp/work" 2>&1)"
    expect "merged branch is deleted" '^  DELETE  merged  '
    expect "rebased branch counts as merged" '^  DELETE  rebased  '
    expect "unmerged branch is kept and its commit shown" '^  KEEP    unmerged  1 commit'
    expect "clean worktree is removed" 'DELETE  .*/wt-clean  \[wt-merged\]'
    expect "dirty worktree is kept" 'KEEP    .*/wt-dirty  \[wt-dirty\] 1 uncommitted'
    expect "branch of a kept worktree is kept" '^  KEEP    wt-dirty  checked out in a kept worktree'
    expect "base is origin/main" '^base: origin/main \(default\)'
    expect "main is kept" '^  KEEP    main  main or the current branch'
    expect "merged remote branch is listed" 'git push origin --delete merged'
    expect "dry run says nothing changed" 'Dry run: nothing changed'
    expect_ref present merged

    echo "dry run from a linked worktree:"
    out="$(cd "$tmp/wt-clean" && bash "$script" --no-gh 2>&1)"
    expect "main checkout is kept" "KEEP    .*/work  \[main\] main checkout"
    expect "current worktree is kept" 'KEEP    .*/wt-clean  \[wt-merged\] main checkout or the current one'
    expect "branch of the current worktree is kept" '^  KEEP    wt-merged  '
    if grep -qE 'DELETE  .*/work  ' <<<"$out"; then
        echo "  FAIL  main checkout listed for DELETE"; fails=$((fails + 1))
    else
        echo "  ok    main checkout not listed for DELETE"
    fi

    echo "--execute:"
    out="$(bash "$script" --no-gh "$tmp/work" --execute 2>&1)" || true
    expect "backup written" 'Branch tips saved to .*/cleanup-backups/branches\.'
    expect_ref absent merged
    expect_ref absent rebased
    expect_ref absent wt-merged
    expect_ref present unmerged
    expect_ref present wt-dirty
    expect_ref present main
    if [ -d "$tmp/wt-clean" ]; then echo "  FAIL  wt-clean should be removed"; fails=$((fails + 1)); else echo "  ok    wt-clean removed"; fi
    if [ -d "$tmp/wt-dirty" ]; then echo "  ok    wt-dirty kept"; else echo "  FAIL  wt-dirty should be kept"; fails=$((fails + 1)); fi

    echo "--execute --include-unmerged:"
    out="$(bash "$script" --no-gh "$tmp/work" --execute --include-unmerged 2>&1)" || true
    expect_ref absent unmerged
    expect_ref present wt-dirty

    # A repository whose default branch is master, with no origin/main. Its
    # main checkout is on a detached HEAD, so master is kept only because it is
    # the base branch.
    (
        set -e
        cd "$tmp"
        git init -q --bare m-origin.git
        git --git-dir=m-origin.git symbolic-ref HEAD refs/heads/master
        git init -q m-work && cd m-work
        git symbolic-ref HEAD refs/heads/master
        echo a > a.txt && git add a.txt && git commit -qm A
        git remote add origin ../m-origin.git && git push -q origin master
        # git 2.48 and newer create origin/HEAD on fetch; keep it unset until the
        # fallback check sets it. Older git ignores this setting.
        git config remote.origin.followRemoteHEAD never
        git checkout -q -b merged && echo b > b.txt && git add b.txt && git commit -qm B
        git push -q origin merged
        git checkout -q master && git merge -q --no-ff --no-edit merged
        git push -q origin master
        git checkout -q -b unmerged && echo d > d.txt && git add d.txt && git commit -qm D
        git checkout -q --detach master
    ) || { echo "FAIL: could not build the master fixture"; return 1; }
    expect_fail() {  # expect_fail <description> <args...>: the run must exit non-zero
        local what="$1"; shift
        if out="$(bash "$script" --no-gh "$tmp/m-work" "$@" 2>&1)"; then
            echo "  FAIL  $what (exited 0)"; fails=$((fails + 1))
        else
            echo "  ok    $what"
        fi
    }

    echo "master default, no --base and no origin/HEAD:"
    expect_fail "stops when neither origin/main nor origin/HEAD exists"
    expect "says to name the base with --base" 'Name the default branch with --base'

    echo "master default, --base origin/master (dry run):"
    out="$(bash "$script" --no-gh "$tmp/m-work" --base origin/master 2>&1)"
    expect "base is origin/master" '^base: origin/master \(from --base\)'
    expect "merged branch is deleted" '^  DELETE  merged  all commits in origin/master'
    expect "local master is kept as the base branch" '^  KEEP    master  master or the current branch'
    expect "unmerged branch is listed" '^  KEEP    unmerged  1 commit\(s\) not in origin/master'
    expect "merged remote branch is listed" 'git push origin --delete merged$'
    if grep -qE 'DELETE  master|--delete.* master' <<<"$out"; then
        echo "  FAIL  master listed for deletion"; fails=$((fails + 1))
    else
        echo "  ok    master not listed for deletion"
    fi

    echo "master default, GIT_CLEANUP_BASE=origin/master:"
    out="$(GIT_CLEANUP_BASE=origin/master bash "$script" --no-gh "$tmp/m-work" 2>&1)"
    expect "base taken from GIT_CLEANUP_BASE" '^base: origin/master \(from GIT_CLEANUP_BASE\)'
    expect "merged branch is deleted" '^  DELETE  merged  all commits in origin/master'

    echo "master default, --base wins over GIT_CLEANUP_BASE:"
    out="$(GIT_CLEANUP_BASE=origin/no-such-branch bash "$script" --no-gh "$tmp/m-work" --base=origin/master 2>&1)"
    expect "base is origin/master" '^base: origin/master \(from --base\)'

    echo "master default, refused bases:"
    expect_fail "a local branch as --base is refused" --base master
    expect "says it is not remote-tracking" 'base master \(from --base\) is not a remote-tracking branch'
    expect_fail "a commit SHA as --base is refused" --base "$(git -C "$tmp/m-work" rev-parse master)"
    expect "says it is not remote-tracking" 'is not a remote-tracking branch'
    expect_fail "a missing remote branch as --base is refused" --base origin/main
    expect "says the base is not found" 'base origin/main \(from --base\) not found'
    if out="$(GIT_CLEANUP_BASE=master bash "$script" --no-gh "$tmp/m-work" 2>&1)"; then
        echo "  FAIL  a local branch in GIT_CLEANUP_BASE should be refused"; fails=$((fails + 1))
    else
        echo "  ok    a local branch in GIT_CLEANUP_BASE is refused"
    fi
    expect "names GIT_CLEANUP_BASE in the error" 'base master \(from GIT_CLEANUP_BASE\) is not a remote-tracking branch'
    if out="$(bash "$script" --no-gh "$tmp/m-work" --base 2>&1)"; then
        echo "  FAIL  --base without a value should be refused"; fails=$((fails + 1))
    else
        echo "  ok    --base without a value is refused"
    fi

    echo "master default, origin/HEAD fallback:"
    git -C "$tmp/m-work" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master
    out="$(bash "$script" --no-gh "$tmp/m-work" 2>&1)"
    expect "base taken from origin/HEAD" '^base: origin/master \(origin/main not found; from origin/HEAD\)'
    expect "merged branch is deleted" '^  DELETE  merged  all commits in origin/master'

    echo "master default, --execute --base origin/master:"
    git -C "$tmp/m-work" symbolic-ref -d refs/remotes/origin/HEAD
    out="$(bash "$script" --no-gh "$tmp/m-work" --execute --base origin/master 2>&1)" || true
    expect_ref absent merged "$tmp/m-work"
    expect_ref present master "$tmp/m-work"
    expect_ref present unmerged "$tmp/m-work"

    if [ "$fails" -gt 0 ]; then echo "RESULT: FAIL - $fails check(s) failed."; return 1; fi
    echo "RESULT: OK - git_cleanup.sh self-test passed."
}

repo=.
execute=0
include_unmerged=0
use_gh=1
want_base=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --execute) execute=1 ;;
        --include-unmerged) include_unmerged=1 ;;
        --no-gh) use_gh=0 ;;
        --base)
            if [ "$#" -lt 2 ] || [ -z "$2" ]; then echo "--base needs a ref, such as origin/master" >&2; exit 2; fi
            want_base="$2"; shift ;;
        --base=*)
            want_base="${1#--base=}"
            if [ -z "$want_base" ]; then echo "--base needs a ref, such as origin/master" >&2; exit 2; fi ;;
        --self-test) self_test; exit $? ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
        *) repo="$1" ;;
    esac
    shift
done
cleanup "$repo" "$execute" "$include_unmerged" "$use_gh" "$want_base"
