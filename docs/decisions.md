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
- status: decided
- choice: when the setup and automation flows stabilize, split the current guidance into two dedicated runbooks
- rationale: one-time human bootstrap and repeatable automation/operations are different concerns and should not stay mixed indefinitely
- consequences: later documentation work should produce:
  - `Human Bootstrap Runbook`
  - `Automation Operations Runbook`
