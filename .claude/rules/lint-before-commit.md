# Pre-commit verification

Always run `make lint` before claiming work is complete or committing.
Always run `make test-unit` before claiming work is complete or committing.
Run `make lint-fix` to auto-format Fish and Markdown files before committing changes to those files.
Never push when `make lint` or any test target reports a failure — fix the failure and re-run.
Never use `git commit --no-verify` to bypass pre-commit hooks unless the user has explicitly asked for it; if a hook fails, investigate and fix the underlying issue.
