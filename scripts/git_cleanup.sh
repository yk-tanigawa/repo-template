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
# Leftover directories: directories directly under
# <main worktree>/.claude/worktrees/ that git does not list as worktrees, such
# as what a failed `git worktree remove` leaves. Each is listed as DELETE when
# nothing would be lost, else KEEP with up to 5 files git does not hold.
# Nothing is lost when every file outside __pycache__/ has content that is a
# blob in the repository, or is identical to the same path in the main checkout
# (such as .env.local), every symlink matches the same path in the main checkout
# (such as _data) or is a tracked symlink, and a top-level .git file only points
# to a git dir. Any other entry, or a failed or short hash-object or cat-file
# run, keeps the directory. --execute checks registration and content again
# right before it deletes each leftover. When `git worktree remove` fails after
# git has unregistered the worktree, the same check runs on what is left and,
# if it passes, rm -rf finishes the job.
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

# ---- leftover directories ----
# A leftover is a directory that is not, or no longer, a registered worktree:
# what `git worktree remove` leaves when it fails after unregistering the
# worktree, or a directory under <main worktree>/.claude/worktrees/ that git
# does not list.

# Print the physical path of every registered worktree, one per line.
registered_paths() {
    local list line p
    list="$(git worktree list --porcelain)" || return 1
    while IFS= read -r line; do
        case "$line" in
            "worktree "*)
                p="${line#worktree }"
                (cd "$p" 2>/dev/null && pwd -P) || echo "$p" ;;
        esac
    done <<<"$list"
}

# Check whether deleting directory $1 would lose anything. Return 0 when
# nothing would be lost: every entry outside __pycache__/ directories is
#   - a regular file whose content is a blob in this repository's object store
#     (git hash-object, then git cat-file --batch-check, one process each), or
#   - a regular file or symlink identical to the one at the same relative path
#     in the main worktree ($main_wt), such as the .env.local and _data link
#     that make worktree-setup puts in a worktree, or
#   - a symlink whose target text is a blob in the object store (a tracked
#     symlink), or
#   - a .git file at the top that only points to a git dir ("gitdir: ...").
# Anything else, including fifos, sockets and devices, is something git lacks.
# Return 1 to keep the directory, with lo_reason set and up to 5 entries git
# lacks in lo_examples. The check fails closed: if find, hash-object or cat-file
# fails, or prints a different number of lines than there are files, or a file
# name contains a newline, the directory is kept with the error as lo_reason.
# On 0, lo_summary describes what was checked.
lo_reason="" lo_examples="" lo_summary=""
leftover_check() {
    local w rc=0
    lo_reason="" lo_examples="" lo_summary=""
    # The main-checkout comparisons need its path; never fall back to /.
    if [ -z "${main_wt:-}" ] || [ ! -d "$main_wt" ]; then
        lo_reason="the content check failed: main checkout not known; review by hand"
        return 1
    fi
    if ! w="$(mktemp -d "${TMPDIR:-/tmp}/git_cleanup_check.XXXXXX")"; then
        lo_reason="the content check failed: could not create a scratch directory; review by hand"
        return 1
    fi
    leftover_check_in "$1" "$w" || rc=$?
    rm -rf "$w"
    return "$rc"
}

# leftover_check for directory $1, with scratch files in directory $2.
leftover_check_in() {
    local d="$1" w="$2" n n_nul n_hash n_check n_lack=0 rel f t
    lack() {  # lack <relative path> [note]
        n_lack=$((n_lack + 1))
        if [ "$n_lack" -le 5 ]; then lo_examples="$lo_examples"$'\n'"$1${2:+ ($2)}"; fi
    }
    # Regular files outside __pycache__, NUL-separated so that a newline in a
    # name shows as a count mismatch rather than as two paths.
    if ! find "$d" -type d -name __pycache__ -prune -o -type f -print0 > "$w/files0" 2> "$w/err" \
        || ! find "$d" -type d -name __pycache__ -prune -o ! -type d ! -type f -print > "$w/other" 2>> "$w/err"; then
        lo_reason="the content check failed: find could not list $d ($(head -n 1 "$w/err")); review by hand"
        return 1
    fi
    if ! tr '\0' '\n' < "$w/files0" > "$w/files" \
        || ! n="$(wc -l < "$w/files" | tr -d ' ')" \
        || ! n_nul="$(tr -cd '\0' < "$w/files0" | wc -c | tr -d ' ')"; then
        lo_reason="the content check failed: could not count the files; review by hand"
        return 1
    fi
    if [ "$n" != "$n_nul" ]; then
        lo_reason="the content check failed: a file name contains a newline; review by hand"
        return 1
    fi
    if [ "$n" -gt 0 ]; then
        if ! git hash-object --stdin-paths < "$w/files" > "$w/hashes" 2> "$w/err"; then
            lo_reason="the content check failed: git hash-object: $(head -n 1 "$w/err"); review by hand"
            return 1
        fi
        n_hash="$(wc -l < "$w/hashes" | tr -d ' ')"
        if [ "$n_hash" != "$n" ]; then
            lo_reason="the content check failed: git hash-object printed $n_hash hash(es) for $n file(s); review by hand"
            return 1
        fi
        if ! git cat-file --batch-check='%(objectname) %(objecttype)' < "$w/hashes" > "$w/checked" 2> "$w/err"; then
            lo_reason="the content check failed: git cat-file: $(head -n 1 "$w/err"); review by hand"
            return 1
        fi
        n_check="$(wc -l < "$w/checked" | tr -d ' ')"
        if [ "$n_check" != "$n" ]; then
            lo_reason="the content check failed: git cat-file checked $n_check of $n hash(es); review by hand"
            return 1
        fi
        # A file is held when cat-file answers "<its hash> blob"; anything
        # else, including a line out of step, counts as missing.
        if ! paste -d '\t' "$w/hashes" "$w/checked" "$w/files" \
            | awk -F '\t' '$2 != $1 " blob" { sub(/^[^\t]*\t[^\t]*\t/, ""); print }' > "$w/missing"; then
            lo_reason="the content check failed: could not compare the hashes; review by hand"
            return 1
        fi
        while IFS= read -r f; do
            rel="${f#"$d"/}"
            if [ "$rel" = .git ] && [ "$(head -c 8 "$f" 2>/dev/null)" = "gitdir: " ]; then continue; fi
            if [ -f "$main_wt/$rel" ] && [ ! -L "$main_wt/$rel" ] && cmp -s "$f" "$main_wt/$rel"; then continue; fi
            lack "$rel"
        done < "$w/missing"
    fi
    while IFS= read -r f; do
        rel="${f#"$d"/}"
        if [ -L "$f" ]; then
            t="$(readlink "$f")" || { lack "$rel" "symlink"; continue; }
            if [ -L "$main_wt/$rel" ] && [ "$(readlink "$main_wt/$rel")" = "$t" ]; then continue; fi
            if git cat-file -e "$(printf '%s' "$t" | git hash-object --stdin)^{blob}" 2>/dev/null; then continue; fi
            lack "$rel" "symlink"
        else
            lack "$rel" "not a regular file or symlink"
        fi
    done < "$w/other"
    if [ "$n_lack" -gt 0 ]; then
        lo_reason="$n_lack file(s) git does not hold, for example:"
        return 1
    fi
    lo_summary="$n file(s) outside __pycache__, all content in git"
}

# Print lo_examples, indented under a KEEP line.
print_lo_examples() { if [ -n "$lo_examples" ]; then sed '/^$/d; s/^/            /' <<<"$lo_examples"; fi; }

# rm -rf the leftover $1, once more if the first try fails (as git's own
# removal can fail with "Directory not empty").
remove_leftover() {
    rm -rf "$1" 2>/dev/null || true
    if [ -e "$1" ]; then sleep 2; rm -rf "$1" || true; fi
    [ ! -e "$1" ]
}

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

    # ---- leftover directories under <main worktree>/.claude/worktrees ----
    local -a lo_delete=()
    local lo_root="$main_wt/.claude/worktrees" regs="" d phys lo_any=0
    echo
    echo "== Leftover directories in $lo_root (not registered worktrees)"
    if [ -z "$main_wt" ]; then
        echo "ERROR: 'git worktree list' named no main worktree; leftover directories not checked" >&2
        return 1
    fi
    if ! regs="$(registered_paths)"; then
        echo "ERROR: 'git worktree list' failed; leftover directories not checked" >&2
        return 1
    fi
    if [ -d "$lo_root" ]; then
        # -type d: a symlink here is not followed or listed.
        while IFS= read -r d; do
            phys="$(cd "$d" 2>/dev/null && pwd -P)" || phys="$d"
            if contains_line "$regs" "$phys"; then continue; fi
            lo_any=1
            if leftover_check "$d"; then
                echo "  DELETE  $d  not a registered worktree; nothing would be lost ($lo_summary)"
                lo_delete+=("$d")
            else
                echo "  KEEP    $d  not a registered worktree; $lo_reason"
                print_lo_examples
            fi
        done < <(find "$lo_root" -mindepth 1 -maxdepth 1 -type d -print | LC_ALL=C sort)
    fi
    if [ "$lo_any" = 0 ]; then echo "  none"; fi

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
    echo "Summary: ${#wt_delete[@]} worktree(s), ${#lo_delete[@]} leftover director(ies) and ${#br_delete[@]} branch(es) to delete;" \
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
            # Clear Python bytecode caches first, which leaves git less to
            # delete. This does not prevent the failure handled below: on some
            # network file systems, `git worktree remove` can stop with
            # "Directory not empty" after it has unregistered the worktree and
            # deleted part of it, for a cause not known. What was left in the
            # cases seen was content git held, and __pycache__.
            if [ -n "$(find "$p" -type d -name __pycache__ -prune -print -quit 2>/dev/null)" ]; then
                find "$p" -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true
                echo "cleared __pycache__ in $p"
            fi
            if git worktree remove "$p"; then
                echo "removed worktree $p"
            elif [ ! -d "$p" ]; then
                failed=1
            elif ! regs="$(registered_paths)"; then
                echo "  kept $p: 'git worktree list' failed, so it is not known whether git still has it" >&2
                failed=1
            elif contains_line "$regs" "$(cd "$p" && pwd -P)"; then
                failed=1  # git kept the worktree; its error is above
            elif leftover_check "$p"; then
                if remove_leftover "$p"; then
                    echo "removed leftover files in $p (all content in git)"
                else
                    echo "  git unregistered $p and nothing in it is missing from git, but rm -rf failed too; rm -rf it later" >&2
                    failed=1
                fi
            else
                echo "  KEEP    $p  git unregistered it but left files; $lo_reason" >&2
                print_lo_examples >&2
                failed=1
            fi
        done
    fi
    if [ "${#lo_delete[@]}" -gt 0 ]; then
        for p in "${lo_delete[@]}"; do
            if [ ! -d "$p" ]; then continue; fi
            # Check again right before deleting: a new worktree may have been
            # registered there, or a file added, since the listing.
            if ! regs="$(registered_paths)"; then
                echo "kept leftover $p: 'git worktree list' failed" >&2
                failed=1
                continue
            fi
            if contains_line "$regs" "$(cd "$p" && pwd -P)"; then
                echo "kept leftover $p: it is now a registered worktree (checked again before deleting)"
                continue
            fi
            if ! leftover_check "$p"; then
                echo "kept leftover $p: $lo_reason (checked again before deleting)"
                print_lo_examples
                continue
            fi
            if remove_leftover "$p"; then
                echo "removed leftover $p (all content in git)"
            else
                echo "  could not remove leftover $p" >&2
                failed=1
            fi
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
        # An ignored bytecode cache in a worktree that will be removed.
        echo '__pycache__/' >> .git/info/exclude
        mkdir -p ../wt-clean/sub/__pycache__ && echo x > ../wt-clean/sub/__pycache__/m.cpython-39.pyc
        # Leftover directories under .claude/worktrees, next to a registered
        # worktree there. lo-clean holds only what git or the main checkout
        # has: committed files, __pycache__, a .git pointer, and an ignored
        # .env.local and _data link like those make worktree-setup puts in a
        # worktree. lo-new also holds a file git does not have.
        printf '.claude/\n.env.local\n_data\n' >> .git/info/exclude
        echo 'LOCAL=1' > .env.local && ln -s ../data-root _data
        git worktree add -q --detach .claude/worktrees/wt-reg main
        lo=.claude/worktrees
        mkdir -p $lo/lo-clean/pkg/__pycache__ $lo/lo-new
        cp a.txt b.txt .env.local $lo/lo-clean/ && ln -s ../data-root $lo/lo-clean/_data
        echo x > $lo/lo-clean/pkg/__pycache__/m.cpython-39.pyc
        echo "gitdir: $tmp/work/.git/worktrees/lo-clean" > $lo/lo-clean/.git
        cp a.txt $lo/lo-new/ && echo 'not committed' > $lo/lo-new/notes.txt
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
    expect "leftover with only content git has is deleted" 'DELETE  .*/\.claude/worktrees/lo-clean  not a registered worktree; nothing would be lost \(4 file'
    expect "leftover with a new file is kept" 'KEEP    .*/\.claude/worktrees/lo-new  not a registered worktree; 1 file\(s\) git does not hold'
    expect "the new file is named" '^            notes\.txt$'
    expect "leftovers are counted in the summary" '^Summary: .* 1 leftover director'
    if grep -qE 'wt-reg  not a registered' <<<"$out"; then
        echo "  FAIL  registered worktree under .claude/worktrees listed as a leftover"; fails=$((fails + 1))
    else
        echo "  ok    registered worktree under .claude/worktrees not listed as a leftover"
    fi
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
    expect "leftovers of the main checkout are listed" 'DELETE  .*/work/\.claude/worktrees/lo-clean  not a registered worktree'

    echo "--execute:"
    out="$(bash "$script" --no-gh "$tmp/work" --execute 2>&1)" || true
    expect "backup written" 'Branch tips saved to .*/cleanup-backups/branches\.'
    expect "__pycache__ cleared before removing a worktree" '^cleared __pycache__ in .*/wt-clean$'
    expect_ref absent merged
    expect_ref absent rebased
    expect_ref absent wt-merged
    expect_ref present unmerged
    expect_ref present wt-dirty
    expect_ref present main
    if [ -d "$tmp/wt-clean" ]; then echo "  FAIL  wt-clean should be removed"; fails=$((fails + 1)); else echo "  ok    wt-clean removed"; fi
    if [ -d "$tmp/wt-dirty" ]; then echo "  ok    wt-dirty kept"; else echo "  FAIL  wt-dirty should be kept"; fails=$((fails + 1)); fi
    expect "leftover is removed" '^removed leftover .*/lo-clean \(all content in git\)$'
    if [ -e "$tmp/work/.claude/worktrees/lo-clean" ]; then echo "  FAIL  lo-clean should be removed"; fails=$((fails + 1)); else echo "  ok    lo-clean removed"; fi
    if [ -f "$tmp/work/.claude/worktrees/lo-new/notes.txt" ]; then echo "  ok    lo-new kept"; else echo "  FAIL  lo-new should be kept"; fails=$((fails + 1)); fi

    echo "--execute --include-unmerged:"
    out="$(bash "$script" --no-gh "$tmp/work" --execute --include-unmerged 2>&1)" || true
    expect_ref absent unmerged
    expect_ref present wt-dirty

    # A stub git in front of the real one. For a worktree named wt-fail-*,
    # `git worktree remove` unregisters and deletes it, puts its files and a
    # __pycache__ back, and fails with "Directory not empty", as a removal can
    # on some network file systems; in wt-fail-new it also leaves a file git
    # does not have. With STUB_GIT_HASH=short, `git hash-object --stdin-paths`
    # drops its last line, as a file vanishing during the check would.
    (
        set -e
        mkdir -p "$tmp/bin-git"
        {
            printf '#!/bin/sh\nreal='\''%s'\''\n' "$(command -v git)"
            cat <<'EOF'
case "$1 $2 ${3##*/}" in
    "worktree remove wt-fail-"*)
        p="$3"
        cp -R "$p" "$p.stub-copy" && "$real" worktree remove "$p" || exit 1
        mv "$p.stub-copy" "$p"
        mkdir -p "$p/pkg/__pycache__" && echo x > "$p/pkg/__pycache__/m.pyc"
        if [ "${p##*/}" = wt-fail-new ]; then echo new > "$p/appeared.txt"; fi
        echo "error: failed to delete '$p': Directory not empty" >&2
        exit 128 ;;
esac
if [ "$1 $2" = "hash-object --stdin-paths" ] && [ "${STUB_GIT_HASH:-}" = short ]; then
    "$real" "$@" | sed '$d'
    exit 0
fi
exec "$real" "$@"
EOF
        } > "$tmp/bin-git/git"
        chmod +x "$tmp/bin-git/git"
        git -C "$tmp/work" worktree add -q --detach "$tmp/wt-fail-ok" main
        git -C "$tmp/work" worktree add -q --detach "$tmp/wt-fail-new" main
        mkdir "$tmp/work/.claude/worktrees/lo-short"
        cp "$tmp/work/a.txt" "$tmp/work/b.txt" "$tmp/work/.claude/worktrees/lo-short/"
    ) || { echo "FAIL: could not build the stub git fixture"; return 1; }

    echo "leftover check fails closed (hash-object prints too few lines):"
    out="$(PATH="$tmp/bin-git:$PATH" STUB_GIT_HASH=short bash "$script" --no-gh "$tmp/work" 2>&1)"
    expect "a short hash list keeps the leftover" 'KEEP    .*/lo-short  not a registered worktree; the content check failed: git hash-object printed 1 hash\(es\) for 2 file\(s\)'
    out="$(PATH="$tmp/bin-git:$PATH" bash "$script" --no-gh "$tmp/work" 2>&1)"
    expect "the same leftover is deleted when the check works" 'DELETE  .*/lo-short  not a registered worktree; nothing would be lost'

    echo "git worktree remove fails after unregistering (stub git, --execute):"
    out="$(PATH="$tmp/bin-git:$PATH" bash "$script" --no-gh "$tmp/work" --execute 2>&1)" || true
    expect "git's error is shown" "failed to delete '.*/wt-fail-ok': Directory not empty"
    expect "what git left is removed" '^removed leftover files in .*/wt-fail-ok \(all content in git\)$'
    expect "a leftover with a new file is kept" 'KEEP    .*/wt-fail-new  git unregistered it but left files; 1 file\(s\) git does not hold'
    expect "the new file is named" '^            appeared\.txt$'
    expect "the kept leftover counts as a failure" 'Some deletions failed'
    expect "listed leftover is removed" '^removed leftover .*/lo-short \(all content in git\)$'
    if [ -e "$tmp/wt-fail-ok" ]; then echo "  FAIL  wt-fail-ok should be removed"; fails=$((fails + 1)); else echo "  ok    wt-fail-ok removed"; fi
    if [ -f "$tmp/wt-fail-new/appeared.txt" ]; then echo "  ok    wt-fail-new kept"; else echo "  FAIL  wt-fail-new should be kept"; fails=$((fails + 1)); fi
    if [ -e "$tmp/work/.claude/worktrees/lo-short" ]; then echo "  FAIL  lo-short should be removed"; fails=$((fails + 1)); else echo "  ok    lo-short removed"; fi
    if [ -f "$tmp/work/.claude/worktrees/lo-new/notes.txt" ]; then echo "  ok    lo-new survives every --execute"; else echo "  FAIL  lo-new should be kept"; fails=$((fails + 1)); fi

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
