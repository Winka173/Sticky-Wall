# Repository workflow

- After completing the user's requested changes and the appropriate checks,
  commit the changes belonging to that task and push the current branch to its
  configured upstream. This is the owner's standing preference.
- Preserve unrelated or unfinished work from the user and other agents. Stage
  the task's files deliberately; never force-push or discard work to make a push
  succeed.
- Report the commit hash, branch and push result. Keep credentials, signing keys,
  build outputs and local review artifacts out of commits.
- A later explicit request to pause, cancel, or avoid committing/pushing overrides
  this default. Do not commit incomplete work merely because a turn ends.
