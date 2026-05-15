# Audit artifacts

Files under `docs/audit/` are written by audit skills (`security-auditor`, `arch-detector`, `arch-auditor`, `doc-auditor`, `nitpicker`, `claude-rules-auditor`). Never edit them by hand.
To update a finding's status, re-run the producing skill — it re-validates open findings and moves resolved ones to a new `### Pass N — YYYY-MM-DD` group under `## Fixed` automatically.
Never include `docs/audit/*` files in code-style lint runs; they intentionally diverge from project Markdown style for compactness.
Never delete an audit findings file to "start clean" — the Fixed/Invalid history is the project's record of what has been resolved and why. Re-running the skill is the correct way to refresh the file.
