#!/usr/bin/env bash
# post_image_assets.sh — push images to a non-branch ref and print Markdown that
# shows them in a GitHub issue or pull request comment. See docs/issue-comments.md
# ("Images in Issues and Pull Requests").
#
# Usage (from inside the repository, with .env.local exported, as `make` does):
#   scripts/post_image_assets.sh [--remote NAME] [--repo OWNER/NAME] [--root-var VAR]
#       [--dry-run] REF_NAME IMAGE [IMAGE ...]
#   scripts/post_image_assets.sh --self-test
#
#   REF_NAME  a short path such as pr-42/before-after; pushed as refs/assets/REF_NAME
#   IMAGE     PNG, JPEG, or GIF files under the root named by --root-var, with
#             distinct base names
#   --root-var  the environment variable that holds the image root
#             (default PROJECT_EXTERNAL_DATA_ROOT)
#
# GitHub's API cannot attach files to comments. This script commits the images on
# their own (a commit with no parent, linked to no branch) and pushes it to
# refs/assets/REF_NAME. A normal `git clone` fetches only branches and tags, so the
# images never enlarge clones, and the ref keeps the commit from being garbage
# collected. The printed Markdown links each image by commit and names its source
# as $VAR/<relative path>, so a lost image can be found and posted again. The
# script refuses to overwrite an existing ref. Prints the Markdown to stdout.

set -euo pipefail

usage() { sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'; }

post() {
    local remote=origin repo="" root_var=PROJECT_EXTERNAL_DATA_ROOT dry_run=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --remote) remote=$2; shift 2 ;;
            --repo) repo=$2; shift 2 ;;
            --root-var) root_var=$2; shift 2 ;;
            --dry-run) dry_run=1; shift ;;
            --) shift; break ;;
            -*) echo "ERROR: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    [ $# -ge 2 ] || { echo "ERROR: need REF_NAME and at least one image (see --help)" >&2; return 2; }
    local name=$1; shift

    case "$root_var" in
        ''|[0-9]*|*[!A-Za-z0-9_]*) echo "ERROR: bad --root-var name: $root_var" >&2; return 2 ;;
    esac
    local root_value="${!root_var:-}"
    [ -n "$root_value" ] || { echo "ERROR: set $root_var in .env.local (see --root-var)" >&2; return 2; }
    [ -d "$root_value" ] || { echo "ERROR: \$$root_var is not a directory" >&2; return 2; }

    case "$name" in
        *..*|/*|*/|*' '*|'') echo "ERROR: bad REF_NAME: $name" >&2; return 2 ;;
    esac
    local ref="refs/assets/$name"
    git check-ref-format "$ref" || { echo "ERROR: not a valid ref name: $ref" >&2; return 2; }

    local root f magic abs b seen i
    root=$(cd "$root_value" && pwd -P)
    local -a rels=() bases=()
    for f in "$@"; do
        [ -f "$f" ] || { echo "ERROR: no such file: $f" >&2; return 2; }
        magic=$(head -c 8 "$f" | od -An -tx1 | tr -d ' \n')
        case "$f" in
            *.png|*.PNG) case "$magic" in 89504e470d0a1a0a) ;; *) magic=bad ;; esac ;;
            *.jpg|*.JPG|*.jpeg|*.JPEG) case "$magic" in ffd8ff*) ;; *) magic=bad ;; esac ;;
            *.gif|*.GIF) case "$magic" in 474946383761*|474946383961*) ;; *) magic=bad ;; esac ;;
            *) echo "ERROR: only PNG, JPEG, and GIF files are posted: $f" >&2; return 2 ;;
        esac
        [ "$magic" != bad ] || { echo "ERROR: contents do not match the extension: $f" >&2; return 2; }
        abs=$(cd "$(dirname "$f")" && pwd -P)/$(basename "$f")
        case "$abs" in
            "$root"/*) rels+=("${abs#"$root"/}") ;;
            *) echo "ERROR: $f is not under \$$root_var" >&2; return 2 ;;
        esac
        b=$(basename "$f")
        for seen in "${bases[@]:-}"; do
            [ "$seen" != "$b" ] || { echo "ERROR: two files named $b" >&2; return 2; }
        done
        bases+=("$b")
    done

    if [ -z "$repo" ]; then
        repo=$(git remote get-url "$remote" | sed -E 's#^(git@[^:]+:|https?://[^/]+/|ssh://git@[^/]+/)##; s#\.git$##')
    fi

    if git ls-remote --exit-code "$remote" "$ref" >/dev/null 2>&1; then
        echo "ERROR: $ref already exists on $remote; choose a new REF_NAME" >&2
        return 1
    fi

    local tree msg commit
    tree=$(
        for i in "${!bases[@]}"; do
            printf '100644 blob %s\t%s\n' "$(git hash-object -w -- "$root/${rels[$i]}")" "${bases[$i]}"
        done | git mktree
    )
    msg="Image assets: $name

Posted in issue or pull request comments; not part of any branch.
Sources, relative to \$$root_var:
$(printf '  %s\n' "${rels[@]}")"
    commit=$(printf '%s\n' "$msg" | git commit-tree "$tree")

    if [ "$dry_run" -eq 1 ]; then
        echo "(dry run: $ref not pushed)" >&2
    else
        git push -q "$remote" "$commit:$ref"
    fi

    for i in "${!bases[@]}"; do
        printf '![%s](https://github.com/%s/blob/%s/%s?raw=true)\n' "${bases[$i]%.*}" "$repo" "$commit" "${bases[$i]}"
        printf 'Source: `$%s/%s`\n\n' "$root_var" "${rels[$i]}"
    done
    printf 'Images are stored at `%s` (commit `%s`), outside every branch.\n' "$ref" "${commit:0:7}"
}

self_test() {
    local script tmp out sha rc fails=0
    script="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/post_image_assets_test.XXXXXX")"
    trap 'rm -rf "$tmp"' RETURN
    export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid
    export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid
    export GIT_CONFIG_NOSYSTEM=1 HOME="$tmp"

    ok() { echo "  ok    $1"; }
    fail() { echo "  FAIL  $1"; fails=$((fails + 1)); }
    check() { if [ "$2" = 0 ]; then ok "$1"; else fail "$1"; fi; }
    run() { (cd "$tmp/work" && TEST_IMAGE_ROOT="$tmp/images" bash "$script" --repo owner/repo --root-var TEST_IMAGE_ROOT "$@"); }
    no_assets() { [ -z "$(git -C "$tmp/work" ls-remote "$tmp/remote.git" 'refs/assets/*')" ]; }

    (
        set -e
        cd "$tmp"
        git init -q --bare remote.git
        git init -q work && cd work
        echo x > README.md && git add README.md && git commit -qm init
        git remote add origin ../remote.git && git push -q origin HEAD:refs/heads/main
        mkdir -p ../images/run1/figures ../images/run1/sub
        printf '\211PNG\r\n\032\n%032d' 0 > ../images/run1/figures/fig1.png
        printf '\211PNG\r\n\032\n%032d2' 0 > ../images/run1/figures/fig2.png
        printf '\377\330\377\340%032d' 0 > ../images/run1/figures/shot.jpg
        printf '\211PNG\r\n\032\n%032d' 0 > ../images/run1/sub/fig1.png
        echo 'not an image' > ../images/run1/figures/fake.png
        echo '<svg/>' > ../images/run1/figures/fig.svg
        printf '\211PNG\r\n\032\n%032d' 0 > ../outside.png
    ) || { echo "FAIL: could not build the fixture"; return 1; }
    local figs="$tmp/images/run1/figures"

    echo "push:"
    out="$(run pr-1/run1 "$figs/fig1.png" "$figs/fig2.png" "$figs/shot.jpg" 2>&1)"; rc=$?
    check "exits 0" "$rc"
    sha="$(git -C "$tmp/work" ls-remote "$tmp/remote.git" refs/assets/pr-1/run1 | cut -f1)"
    if [ -n "$sha" ]; then ok "ref pushed"; else fail "ref pushed"; sha=missing; fi
    [ "$(git -C "$tmp/work" rev-list --parents -n 1 "$sha" 2>/dev/null)" = "$sha" ]; check "commit has no parent" $?
    [ "$(git -C "$tmp/work" ls-tree --name-only "$sha" 2>/dev/null | tr '\n' ' ')" = "fig1.png fig2.png shot.jpg " ]; check "tree holds the images by base name" $?
    printf '%s\n' "$out" | grep -qF "![fig1](https://github.com/owner/repo/blob/$sha/fig1.png?raw=true)"; check "Markdown links the image by commit" $?
    printf '%s\n' "$out" | grep -qF 'Source: `$TEST_IMAGE_ROOT/run1/figures/shot.jpg`'; check "Markdown names the source by variable" $?
    printf '%s\n' "$out" | grep -qF "$tmp"; [ $? != 0 ]; check "no absolute path in the Markdown" $?
    git -C "$tmp/work" log -1 --format=%B "$sha" 2>/dev/null | grep -qF run1/figures/fig2.png; check "commit message lists the sources" $?

    git clone -q --no-local "$tmp/remote.git" "$tmp/clone" 2>/dev/null
    git -C "$tmp/clone" cat-file -e "$sha" 2>/dev/null; [ $? != 0 ]; check "a plain clone does not fetch the images" $?

    out="$(run pr-1/run1 "$figs/fig1.png" 2>&1)"; rc=$?
    [ "$rc" = 1 ] && printf '%s\n' "$out" | grep -q 'already exists'; check "an existing ref is not overwritten" $?

    echo "dry run:"
    out="$(run --dry-run pr-2/run1 "$figs/fig1.png" 2>&1)"; rc=$?
    check "exits 0" "$rc"
    [ -z "$(git -C "$tmp/work" ls-remote "$tmp/remote.git" refs/assets/pr-2/run1)" ]; check "nothing pushed" $?
    printf '%s\n' "$out" | grep -qF '![fig1](https://github.com/owner/repo/blob/'; check "Markdown still printed" $?

    echo "refused input:"
    rm -rf "$tmp/remote.git/refs/assets"
    local args
    for args in "r1 $tmp/outside.png" "r2 $figs/fake.png" "r3 $figs/fig.svg" "../bad $figs/fig1.png" \
        "r4 $figs/fig1.png $tmp/images/run1/sub/fig1.png" "r5/ $figs/fig1.png"; do
        # shellcheck disable=SC2086
        run $args >/dev/null 2>&1; rc=$?
        [ "$rc" = 2 ]; check "refused: ${args//$tmp\//}" $?
    done
    (cd "$tmp/work" && env -u TEST_IMAGE_ROOT bash "$script" --repo owner/repo --root-var TEST_IMAGE_ROOT r6 "$figs/fig1.png" >/dev/null 2>&1); rc=$?
    [ "$rc" = 2 ]; check "refused: root variable unset" $?
    no_assets; check "no refs pushed by refused runs" $?

    if [ "$fails" -gt 0 ]; then echo "RESULT: FAIL - $fails check(s) failed."; return 1; fi
    echo "RESULT: OK - post_image_assets.sh self-test passed."
}

case "${1:-}" in
    --self-test) set +e; self_test; exit $? ;;
    -h|--help) usage; exit 0 ;;
esac
post "$@"
