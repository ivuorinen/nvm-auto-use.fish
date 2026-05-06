---
paths:
  - "Makefile"
  - "**/*.mk"
---

# Makefile style

Use tab indentation. Never spaces.
Keep lines at or under 80 characters.
For unavoidable long lines (e.g. Renovate `# renovate: datasource=...` markers with long depNames), prefix the offending line with `# editorconfig-checker-disable-next-line` rather than relaxing the global 80-char limit.
Pin every npm-installed tool via a `# renovate: datasource=npm depName=<package>` comment immediately above its `<NAME>_VERSION := <version>` variable. Invoke pinned tools through `npx --yes <tool>@$(<NAME>_VERSION)`, never through unpinned `npm install -g`.
Pin every GitHub-released binary via `# renovate: datasource=github-releases depName=<owner>/<repo>` above its version variable.
End every file with a final newline; the editorconfig check enforces this and CI will fail without it.
