# Decisions

## Decision Log

### Vector Backend For CI/CD Rebuild

- date: 2026-05-10
- status: decided
- choice: use `Pinecone` as the default vector backend for `ingestra_cicd`
- rationale: `Pinecone` provisioning is straightforward to automate and avoids coupling the rebuild to the existing `Qdrant` estate
- consequences: the old implementation remains a useful reference, but provider-specific retrieval and indexing behavior must be adapted

### Homogeneous Architecture Boundary

- date: 2026-05-10
- status: decided
- choice: keep the solution homogeneous at the workflow-contract level, not at each vendor API surface
- rationale: perfect provider symmetry would add needless complexity; stable internal contracts provide most of the benefit
- consequences: provider adapters can differ internally while CI, tests, and document lifecycle remain stable

### PowerShell As Primary Automation Surface

- date: 2026-05-10
- status: decided
- choice: prefer `PowerShell` scripts for provider configuration, smoke tests, and orchestration where APIs or CLIs allow it
- rationale: this matches the operating preference for the project and keeps local and CI execution aligned
- consequences: scripts must stay modular, testable, and safe to rerun

### Manual Bootstrap Boundary

- date: 2026-05-10
- status: decided
- choice: accept one-time manual bootstrap for provider/org creation and token issuance, then automate the rest
- rationale: this is the honest boundary for systems that require an authenticated tenancy before API use
- consequences: setup docs must distinguish clearly between one-time manual steps and repeatable repo-owned automation

### Future Runbook Split

- date: 2026-05-11
- status: implemented
- choice: split setup guidance into dedicated runbooks, with the human bootstrap flow extracted first
- rationale: one-time human bootstrap and repeatable automation/operations are different concerns and should not stay mixed indefinitely
- consequences:
  - the ordered manual setup checklist now lives in `docs/human-bootstrap-runbook.md`
  - `docs/setup.md` now serves as a boundary/orientation document instead of carrying the full manual checklist
  - the automation operations guidance now lives in `docs/automation-operations-runbook.md`

### Azure Bootstrap Identity Boundary

- date: 2026-05-11
- status: decided
- choice: use a bootstrap Azure app registration with temporary elevated permissions for Azure app-registration automation, and keep the Supabase sign-in app registration as an automation-created resource after the Supabase project exists
- rationale: the Supabase OAuth redirect URI depends on the Supabase project ref, so the Azure sign-in app registration cannot be finalized during early manual bootstrap
- consequences:
  - the human bootstrap layer records and stores the Azure bootstrap identity only
  - automation must create the Supabase project before completing the Azure sign-in app registration
  - bootstrap-only elevated Azure permissions should be reduced or removed after use
