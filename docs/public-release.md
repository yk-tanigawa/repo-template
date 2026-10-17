# Public Release Checklist

Use this checklist when a private repository, or part of one, is about to become public. Making a repository public cannot be fully undone: once content is published, it may be cloned, forked, cached, or indexed.

Agents must not create a public repository, change a repository's visibility, or push to a public remote without explicit approval from the human maintainer for that release.

## Publish a Snapshot Without History

Recommend that the maintainer publish a new repository built from the latest snapshot, with a fresh git history, rather than switching the existing repository to public.

Switching visibility publishes everything the repository holds: every past commit, branch, and tag, plus issues, pull requests, and review comments. Old commits may still contain removed secrets, personal data, raw files, machine-local paths, or references to private repositories. Rewriting history to remove them is easy to get wrong and does not cover issue or pull request text.

Keep the private repository private. Decide with the maintainer where development continues after the release:

- **Public repository becomes canonical.** Development moves to the public repository. Archive the private one or keep it only for private material.
- **Private repository stays canonical.** Each later release repeats this checklist and publishes a new snapshot commit to the public repository.

## 1. Decide the Scope

- [ ] Confirm with the maintainer which files and directories will be published.
- [ ] Confirm the public repository's owner, name, license, and README.
- [ ] Move material that must stay private out of the release, or mark it `export-ignore` in `.gitattributes` so `git archive` skips it.

## 2. Remove References to Private Repositories

Follow "References to Private Repositories" in `docs/writing-guide.md`. Search the tracked files for:

- [ ] URLs to private repositories, their issues, pull requests, commits, or files
- [ ] cross-repository shorthand such as `owner/private-repo#123`
- [ ] private repository names and paths inside them
- [ ] "adopted from", "see the discussion in", or similar notes that point to private work
- [ ] references to issue or pull request numbers in this repository, which will not exist in the new public repository
- [ ] submodules in `.gitmodules`, package dependencies, CI workflows under `.github/`, `CODEOWNERS`, and badges that point to private repositories

Example search, run from the repository root:

```bash
git ls-files -z | xargs -0 grep -nIE '<private-org>/|<private-repo-name>|#[0-9]+'
```

Replace each hit with content restated on its own terms, a public link, or nothing.

## 3. Remove Sensitive and Local Content

- [ ] Secrets, tokens, and credentials. Run a secret scanner such as `gitleaks` or `trufflehog` on the snapshot, and rotate any credential that was ever committed.
- [ ] Individual-level data and personal information. Follow `docs/privacy-guide.md`.
- [ ] Machine-local absolute paths and private data roots.
- [ ] Unpublished drafts, correspondence, reviewer comments, and other material the maintainer has not approved for release.
- [ ] Large, raw, or received files that belong in external storage. Follow `docs/external-data-layout.md`.
- [ ] Third-party content without a license that permits redistribution. Keep required notices.

## 4. Build the Snapshot

Start from a clean, reviewed commit in the private repository. `git archive` exports only tracked files at that commit, so ignored files such as `.env.local`, `_inbox/`, `_data/`, and `_repos/` links stay behind.

```bash
git -C <private-clone> status --short        # expect no output
mkdir <public-clone>
git -C <private-clone> archive --format=tar HEAD | tar -x -C <public-clone>
git -C <public-clone> init -b main
git -C <public-clone> add -A
git -C <public-clone> commit -m "Initial public release"
```

Write the commit message so it does not reference the private repository.

## 5. Review Before Publishing

- [ ] Rerun the searches from steps 2 and 3 in `<public-clone>`.
- [ ] Run the project's validation target, such as `make build` or `make test`, in `<public-clone>`.
- [ ] Have the maintainer review the full file list (`git -C <public-clone> ls-files`) and approve the release.

## 6. Publish

After the maintainer approves, create the public repository and push the snapshot, for example:

```bash
gh repo create <owner>/<public-repo> --public --source=<public-clone> --push
```

Then check the published repository in a browser while signed out, and record the release date and the private commit it was built from in a private location, such as a release log in the private repository. Do not record that link in the public repository.
