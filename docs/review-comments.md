# Replying to Review Comments

Use this guide when replying to a review comment on an issue or pull request, whether a person or an agent writes the reply. It sets one pattern so the reviewer can tell at a glance that the comment has been seen, and then what came of it.

## Two-Step Reply

When a reviewer comments on an issue or pull request and someone takes the work on, reply in two steps.

1. **Acknowledge when you start.** Post a short reply in the same thread before doing the work. Say what you are doing, and that the reply will be replaced with the result:

   ```markdown
   On it: checking the cited paper's Methods for how the cutoff was chosen. I'll replace this comment with the result.
   ```

2. **Replace the acknowledgement with the result.** When the work is pushed, edit that same comment rather than posting a new one. The thread then holds one reply per review comment. The finished reply states:
   - what changed, with the commit and the file;
   - the evidence, such as a source quoted, a test run, or a job ID;
   - what was not done, and any new issue opened for it, linked as `#N`;
   - any decision left to the reviewer.

3. **Update the description.** A pull request's description, like an issue body, is the current state. Edit the description with what the review changed, for example in an "Update after review" section that names the commits. Keep the rest of the description accurate, such as counts or file names that the change made stale.

## Editing a Comment From the Command Line

Take the comment's ID from its URL (`#issuecomment-<ID>`), write the reply to a local file, and run:

```bash
gh api -X PATCH repos/<owner>/<repo>/issues/comments/<ID> -F body=@reply.md
```

Keep the reply file outside tracked paths, or delete it after use.

## Public Repositories

In a public repository, follow the cross-repository reference rule in `docs/writing-guide.md`. Do not cite issues, pull requests, commits, or files from a private repository in a reply, even when the work was motivated there.
