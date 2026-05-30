# Related Repositories

Use this document when a project needs local context from sibling or upstream repositories without vendoring their files into this repository.

This convention is for local context and source references. If another repository is a pinned build dependency, document the package, submodule, or release process separately.

## Convention

Use `_repos/` for ignored local symlinks to related repository clones. Each entry should point to an existing clone on the current machine, such as `_repos/[repo-name]`.

Keep `_repos/` out of git. Treat the related repository as an external source of truth. Do not copy files from a related repository into tracked files here unless the project explicitly needs a local copy and the human maintainer confirms it is appropriate.

Document each related clone path in `.env.local.example` with a project-specific variable, such as:

```bash
# PROJECT_EXAMPLE_REPO=    # path to the related repository clone
```

The actual machine path belongs in `.env.local`, which is ignored. Tracked docs should refer to the local symlink path, the environment variable, or a repository URL rather than a machine-local absolute path.

## Setup

For each related repository:

1. Add a commented variable to `.env.local.example`.
2. Add the real clone path to `.env.local`.
3. Create a local symlink under `_repos/`.
4. Document why the project needs the related repository and which files are source of truth.
5. Update `make setup` or another documented check if the link is required for normal work.

Example local setup:

```bash
mkdir -p _repos
ln -s "$PROJECT_EXAMPLE_REPO" _repos/[repo-name]
```

If the related repository is optional, document which workflows need it and let unrelated `make` targets run without it.

## Privacy and Boundaries

Apply the same privacy and source-control rules to related repositories that you apply here. If a related repository contains private data, individual-level records, credentials, unpublished drafts, or restricted source material, do not summarize or copy that material into tracked files unless the project has an explicit documented reason and the human maintainer confirms it is appropriate.

When cross-repo context affects a durable convention, document the convention in this repository. Use links or path references to identify the source material instead of duplicating content.
