# Architecture Audit Findings
Generated: 2026-05-08
Last validated: 2026-05-08

## Summary
- Total: 2 | Open: 0 | Fixed: 2 | Invalid: 0

## Open Findings

## Fixed

### Pass 1 — 2026-05-08

#### [AA-001] `nvm_compat_detect.fish` defines three public functions
Fixed: 2026-05-08
Notes: Moved `nvm_compat_use` to `functions/nvm_compat_use.fish` and
  `nvm_compat_install` to `functions/nvm_compat_install.fish`. Removed both
  from `nvm_compat_detect.fish`. No callers changed — `nvm_auto_use.fish`
  calls these functions by name and Fish autoloads them from their new files.

#### [AA-002] `nvm_version_prompt.fish` defines two public functions
Fixed: 2026-05-08
Notes: Moved `nvm_version_status` to `functions/nvm_version_status.fish`.
  Removed from `nvm_version_prompt.fish`. No callers changed.

## Invalid
