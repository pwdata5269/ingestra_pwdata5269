# Setup

## Purpose

This document defines the bootstrap boundary and points to the canonical runbooks.

## Assumptions

- `Azure` already exists and is usable for this project
- the `GitHub` repository already exists
- `Qdrant` already exists but is not the default target for this repo
- this repo provisions against `Pinecone`

## Boundary

Manual bootstrap covers the first trust-establishing steps that cannot safely start from repo automation alone.

Repo automation covers repeatable validation, provisioning, and testing after those prerequisites exist.

Repo-owned automation is expected to be idempotent so repeated runs do not create duplicate resources and can safely converge on the intended state.

## Manual Bootstrap

These steps are intentionally manual because automation cannot safely begin before credentials or tenancy exist:

- ensure the `GitHub` repository is `public` for the current `Vercel Hobby` deployment model
- create or confirm the base `Supabase` account/org
- create a `Supabase` PAT with rights to manage projects
- create or confirm the base `Vercel` account/team
- authorize `Vercel` to access the target `GitHub` repository or repository set
- create a `Vercel` token with project-management rights
- create or confirm the base `Pinecone` account and API key
- create or confirm the Azure bootstrap app registration and required bootstrap permissions
- store the resulting values in `GitHub Actions` secrets

Use the dedicated human runbook for the ordered checklist:

- [human-bootstrap-runbook.md](/C:/Projects/ingestra_pwdata5269/docs/human-bootstrap-runbook.md)

## Repo Automation Boundary

The repo currently automates or validates these areas:

- secret contract validation
- `Supabase` project creation
- Azure app-registration creation or update for `Supabase` login
- `Vercel` project creation
- `Vercel` GitHub repository linkage after manual repository authorization
- generation of a static frontend runtime config during CI for the auth harness
- direct frontend deployment to `Vercel` from `GitHub Actions`
- browser-based Azure login verification through the deployed auth harness
- `Pester` test execution in CI
- `Pinecone` index creation, confirmation, and deletion
- basic smoke-test execution against configured HTTP endpoints

The repo does not yet fully automate:

- `Supabase` post-create configuration
- one-time `Vercel` GitHub repository authorization
- `n8n` deployment and CI-compatible validation
- full end-to-end upload, retrieval, and chat fixtures

## Current Required Secrets

Current repo-owned automation expects these secrets when relevant:

- `AZURE_TENANT_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_DB_URL`
- `SUPABASE_ORG_SLUG`
- `SUPABASE_DB_PASSWORD`
- `VERCEL_TOKEN`
- `PINECONE_API_KEY`

Optional or later secrets:

- `VERCEL_TEAM_ID`
- `VERCEL_PROJECT_NAME`
- `SUPABASE_PROJECT_NAME`
- `INGESTRA_UPLOAD_URL`
- `INGESTRA_SEARCH_URL`
- `INGESTRA_CHAT_URL`

`SUPABASE_DB_URL` should currently be the real Supabase session-pooler connection string used for schema automation, for example:

```text
postgresql://postgres.<project-ref>:<password>@aws-0-<region>.pooler.supabase.com:5432/postgres
```

## Local Validation

To validate the bootstrap contract locally:

```powershell
pwsh -File .\scripts\Test-BootstrapPrereqs.ps1 -Profile provision
```

To create or confirm the default index locally:

```powershell
pwsh -File .\scripts\providers\Pinecone.ps1 `
  -Action EnsureIndex `
  -IndexName ingestra-ci `
  -Dimension 1024 `
  -Metric cosine `
  -Cloud aws `
  -Region us-east-1
```

## Smoke Tests

When the runtime endpoints exist, validate them with:

```powershell
pwsh -File .\scripts\Invoke-IngestraSmokeTests.ps1
```
