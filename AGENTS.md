# Frostmere contributor instructions

Read [PROJECT.md](PROJECT.md), the pinned [method](.agent-temper/METHOD.md),
the selected [GitHub profile](.agent-temper/profiles/github.md), and the issue
with its comments before edits. GitHub Issues own all live work.

- Select one bounded delivery batch. Preserve save IDs, progression gates and
  test isolation. Record discoveries before expanding scope.
- Follow [contributor checks](CONTRIBUTING.md). Never use normal player saves for tests.
- Use the original detailed block-built art direction. Keep the core adventure
  single-player; destination chapters support the Nordic world.
- Obtain a separate review before integration. For agent-led changes, delegate
  a read-only final-candidate review to a reviewer subagent; resolve findings and
  record its scope and limitations in the issue or PR. This authorizes review
  delegation, not parallel feature implementation.
- Agents may commit, push, open PRs and merge after checks and separate review.
  Releases, tags, packages for publication, deployments, paid services and changes
  to policy or repository permissions require the owner's explicit authorization.
- Run `python3 tools/verify_repo.py`; use the focused Godot checks in CONTRIBUTING.md
  for code/configuration changes. Keep actual evidence and continuation in GitHub.
- Never commit local engine binaries, build output, player profiles, credentials,
  private paths or personal data. Historical docs are evidence, not live task lists.
