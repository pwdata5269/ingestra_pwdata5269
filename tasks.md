# Tasks

## Current Status

- legacy `Ingestra` requirements and implementation notes reviewed
- new repo positioned as CI/CD rebuild rather than direct runtime clone
- `Pinecone` selected as the default vector backend for this repo
- initial documentation and automation scaffold added
- bootstrap validation, `Pinecone` provisioning, smoke-test entrypoints, and CI workflows defined
- `Supabase` project provisioning is now wired into `GitHub Actions` and has been proven through `EnsureProject`
- Azure app-registration automation for `Supabase` login is now wired into `GitHub Actions` and has been proven, including idempotent client-secret creation on rerun
- `Supabase` auth is now visibly enabled for Azure login
- `Vercel` project creation and GitHub repo linkage are now proven in `GitHub Actions`
- the `Vercel` auth harness has been deployed successfully and Azure login through `Supabase` has been manually proven end to end

## Next Tasks

- implement `Supabase` post-create configuration steps, starting with applying checked-in SQL schema and RLS
- define the `n8n` deployment model for CI-compatible validation
- add environment-specific config templates
- add end-to-end test fixtures for upload, retrieval, and chat
- decide whether parser-service validation runs in CI or only in a gated environment

## Deliverables

- repeatable `GitHub Actions` workflows
- `PowerShell` scripts for configuration and testing
- `Pester` tests for automation quality gates
- canonical docs for setup, workflow, observability, and decisions

## Acceptance Criteria

- a maintainer can identify manual bootstrap steps in one pass
- the repo can validate whether required secrets are present
- the repo can create a `Supabase` project from CI-owned secrets and config
- the repo can rerun provider automation safely without duplicating resources
- the repo can create or update the Azure login app and emit a usable client secret for the current run
- the repo can configure `Supabase` to use Azure login successfully
- the repo can create a `Vercel` project and, once `Vercel` has been granted access to the repository, ensure repository linkage successfully
- the repo can generate a static frontend runtime config and deploy the frontend to `Vercel` from `GitHub Actions`
- the repo can prove Azure login end to end through the deployed `Vercel` auth harness
- the repo has a checked-in SQL schema source for the initial `Supabase` tables and RLS posture
- the repo can create or reset a test `Pinecone` index from CI inputs
- smoke tests can fail fast with actionable output
- future `Qdrant` support can be added without reworking the entire repo shape
