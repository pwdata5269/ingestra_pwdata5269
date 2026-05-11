# Process

## Canonical Files

- `tasks.md` is the execution checkpoint
- `spec.md` is the architecture and acceptance source of truth
- `docs/decisions.md` records durable choices
- `docs/setup.md` defines bootstrap and automation boundaries
- `docs/human-bootstrap-runbook.md` is the canonical ordered manual setup checklist
- `docs/automation-operations-runbook.md` is the canonical automation operations guide
- `config/automation-config.json` is the machine-readable automation source of truth
- `docs/workflow.md` defines automation boundaries
- `docs/observability.md` defines validation and reporting expectations

## Rules

- prefer updating an existing markdown file over creating a new one
- put repeatable runtime work behind `scripts/`
- keep provider automation scripts under `scripts/providers/`
- keep shared PowerShell helpers under `scripts/modules/`
- keep `Pester` tests under `tests/`
- name test files by provider or contract area, for example `Supabase.Provider.Tests.ps1`
- make every automation step idempotent so reruns converge on the intended state rather than duplicating resources
- keep provider-specific behavior isolated from cross-provider workflow contracts
- treat CI secrets as inputs to scripts, not as logic baked into workflows
