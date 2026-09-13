# Global agent instructions

## GitHub identity

- All GitHub repository mutations performed by an agent must use the `xdega-bot` GitHub App, never Liam's `xdega` user credentials.
- This includes commits intended for GitHub, pushes, pull-request creation or updates, issue or discussion changes, releases, labels, reviews, comments, merges, and other write operations.
- For the supported commit/push/pull-request workflow, use `xdega-bot-pr`. Do not run `git commit`, `git push`, or a mutating `gh` command separately.
- Personal `gh` authentication may be used only for read-only inspection.
- If `xdega-bot-pr` does not support the required mutation, the App is not installed on the repository, or App authentication fails, stop and ask Liam rather than falling back to personal credentials.
- Do not merge or enable auto-merge unless the active repository's own instructions and Liam's explicit request authorize it.
