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

### Supabase As First Proven Automation Step

- date: 2026-05-11
- status: implemented
- choice: make `Supabase` project provisioning the first external provider step exercised through `GitHub Actions`
- rationale: `Supabase` project creation is upstream of the Azure OAuth redirect dependency and provides a clean first proof that secret-backed provider automation works end to end
- consequences:
  - `provision-test.yml` now runs `Supabase` `EnsureProject` before `Pinecone`
  - the current configured `Supabase` project has been created successfully through automation
  - follow-on work should focus on Azure app-registration automation and `Supabase` post-create configuration

### Idempotent Automation Requirement

- date: 2026-05-11
- status: decided
- choice: require all provider automation steps to be idempotent
- rationale: the repo is intended to be rerun safely in CI and by maintainers without duplicating resources or depending on one-time transient state
- consequences:
  - provider scripts should prefer `Ensure*` behavior over one-shot create semantics
  - existing resources must be reconciled to the intended state where feasible
  - automation should regenerate transient values when needed for the current run rather than assuming earlier run outputs still exist

### Azure Login App Automation Proven

- date: 2026-05-11
- status: implemented
- choice: automate Azure `Supabase` login app creation and rerun-safe client-secret generation inside the provisioning workflow
- rationale: the Azure sign-in app is part of the provider automation boundary, and the workflow needs a usable client secret on every relevant run
- consequences:
  - `provision-test.yml` now proves the Azure login app step in `GitHub Actions`
  - the Azure step now emits a fresh client secret for the current run even when the app already exists
  - the next integration target is applying those Azure values into `Supabase` auth configuration

### Supabase Azure Auth Configuration Proven

- date: 2026-05-12
- status: implemented
- choice: configure `Supabase` auth to use the generated Azure sign-in app as part of provisioning
- rationale: Azure login needed to be proven in the live `Supabase` project before moving on to the browser-based `Vercel` auth test harness
- consequences:
  - `Supabase` now visibly shows Azure login as enabled
  - the next major implementation target is `Vercel` project automation
  - the next major validation target is an end-to-end browser login test through the minimal frontend

### Vercel Git Authorization Boundary

- date: 2026-05-12
- status: decided
- choice: treat `Vercel` access to the target `GitHub` repository as a one-time manual bootstrap prerequisite, while keeping project creation and repo linkage as automation-owned steps after that access exists
- rationale: the live workflow proved that project creation succeeds but repository connection fails until `Vercel` has been explicitly authorized to see and use the repository
- consequences:
  - the human bootstrap runbook must require `Vercel` GitHub authorization before provisioning
  - automation may assume repository visibility only after that prerequisite is complete
  - `Vercel` repo-link failures before authorization should be treated as bootstrap gaps, not script defects
