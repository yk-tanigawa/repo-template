# Related Repositories

Use this document when a project needs local context from sibling or upstream repositories without vendoring their files into this repository.

This convention is for local context and source references. If another repository is a pinned build dependency, document the package, submodule, or release process separately.

## Convention

Use `_repos/` for ignored local symlinks to related repository clones. Each entry should point to an existing clone on the current machine, such as `_repos/[repo-name]`. The template tracks `_repos/README.md` so the directory exists in fresh clones and carries local-use guidance. All other `_repos/` entries are ignored.

Keep related repository entries out of git. Treat each related repository as an external source of truth. Do not copy files from a related repository into tracked files here unless the project explicitly needs a local copy and the human maintainer confirms it is appropriate.

Document each related clone path in `.env.local.example` with a project-specific variable. Then list the `_repos/` link name and variable name in `PROJECT_RELATED_REPOS`:

```bash
# PROJECT_EXAMPLE_REPO=       # path to the related repository clone
# PROJECT_RELATED_REPOS=example:PROJECT_EXAMPLE_REPO
```

The actual machine path belongs in `.env.local`, which is ignored. Tracked docs should refer to the local symlink path, the environment variable, or a repository URL rather than a machine-local absolute path.

Use one `PROJECT_RELATED_REPOS` entry per related clone. The entry format is `link-name:ENV_VAR`, where `link-name` becomes `_repos/link-name` and `ENV_VAR` stores the machine-local clone path. Link names should be plain directory names without slashes or leading dots.

## Setup

For each related repository:

1. Add a commented variable to `.env.local.example`.
2. Add or update `PROJECT_RELATED_REPOS` in `.env.local.example`.
3. Add the real clone path to `.env.local`.
4. Run `make setup` to create or refresh the local symlink under `_repos/`.
5. Confirm `git status --short` does not show the local symlink.
6. Document why the project needs the related repository and which files are source of truth.
7. Update project-specific setup checks if the related repository is required for normal work.

Example `.env.local` entries:

```bash
PROJECT_EXAMPLE_REPO=/path/to/example
PROJECT_RELATED_REPOS=example:PROJECT_EXAMPLE_REPO
```

Then run:

```bash
make setup
```

If the related repository is optional, document which workflows need it and let unrelated `make` targets run without it.

## Privacy and Boundaries

Apply the same privacy and source-control rules to related repositories that you apply here. If a related repository contains private data, individual-level records, credentials, unpublished drafts, or restricted source material, do not summarize or copy that material into tracked files unless the project has an explicit documented reason and the human maintainer confirms it is appropriate.

When cross-repo context affects a durable convention, document the convention in this repository. Use links or path references to identify the source material instead of duplicating content.
