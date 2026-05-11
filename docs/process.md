# Process

## Canonical Files

- `tasks.md` is the execution checkpoint
- `spec.md` is the architecture and acceptance source of truth
- `docs/decisions.md` records durable choices
- `docs/setup.md` defines bootstrap and environment expectations
- `docs/workflow.md` defines automation boundaries
- `docs/observability.md` defines validation and reporting expectations

## Rules

- prefer updating an existing markdown file over creating a new one
- put repeatable runtime work behind `scripts/`
- keep provider-specific behavior isolated from cross-provider workflow contracts
- treat CI secrets as inputs to scripts, not as logic baked into workflows
