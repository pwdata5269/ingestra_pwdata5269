# Tasks

## Current Status

- legacy `Ingestra` requirements and implementation notes reviewed
- new repo positioned as CI/CD rebuild rather than direct runtime clone
- `Pinecone` selected as the default vector backend for this repo
- initial documentation and automation scaffold added
- bootstrap validation, `Pinecone` provisioning, smoke-test entrypoints, and CI workflows defined

## Next Tasks

- implement `Supabase` project creation and post-create configuration steps
- implement `Vercel` project creation and environment-variable wiring
- define the `n8n` deployment model for CI-compatible validation
- add environment-specific config templates
- add end-to-end test fixtures for upload, retrieval, and chat
- decide whether parser-service validation runs in CI or only in a gated environment
- promote the current setup/bootstrap guidance into dedicated runbooks once the flow stabilizes:
  - `Human Bootstrap Runbook`
  - `Automation Operations Runbook`

## Deliverables

- repeatable `GitHub Actions` workflows
- `PowerShell` scripts for configuration and testing
- `Pester` tests for automation quality gates
- canonical docs for setup, workflow, observability, and decisions

## Acceptance Criteria

- a maintainer can identify manual bootstrap steps in one pass
- the repo can validate whether required secrets are present
- the repo can create or reset a test `Pinecone` index from CI inputs
- smoke tests can fail fast with actionable output
- future `Qdrant` support can be added without reworking the entire repo shape
