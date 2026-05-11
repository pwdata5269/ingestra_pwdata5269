# Setup

## Purpose

This document defines the bootstrap boundary and the repo-owned automation boundary.

## Assumptions

- `Azure` already exists and is usable for this project
- the `GitHub` repository already exists
- `Qdrant` already exists but is not the default target for this repo
- this repo provisions against `Pinecone`

## Manual Bootstrap

These steps are intentionally manual because automation cannot safely begin before credentials or tenancy exist:

- create or confirm the base `Supabase` account/org
- create a `Supabase` PAT with rights to manage projects
- create or confirm the base `Vercel` account/team
- create a `Vercel` token with project-management rights
- create or confirm the base `Pinecone` account and API key
- store the resulting values in `GitHub Actions` secrets

## Bootstrap Checklist

This is the minimum manual setup required before repo automation can take over.

### 1. VPS

- create a `Contabo` VPS or equivalent test VPS
- choose `Ubuntu 24.04 LTS` if available, otherwise `Ubuntu 22.04 LTS`
- confirm the VPS has:
  - `4 vCPU`
  - `8 GB RAM`
  - `75 GB NVMe`
- confirm you can connect over `SSH`
- record:
  - server IP address
  - SSH username
  - SSH private key location

### 2. DNS and URLs

- decide whether the test environment will use a real domain or direct IP-based access
- if using a domain, create the required DNS records
- decide the intended public hostnames for:
  - `n8n`
  - optional parser service health endpoint
  - optional future MCP/API endpoint
- decide whether `HTTPS` will be terminated by `Nginx` or `Caddy` on the VPS

### 3. GitHub

- confirm the target repository exists
- confirm you have admin rights to add `Actions` secrets
- confirm `GitHub Actions` is enabled for the repo
- decide the branch strategy for deployment, for example:
  - deploy from `main`
  - deploy from a dedicated environment branch

### 4. Azure

- confirm the existing Azure tenant and bootstrap identity are still valid
- have these values available:
  - `AZURE_TENANT_ID`
  - `AZURE_CLIENT_ID`
  - `AZURE_CLIENT_SECRET`
- confirm the app registration or bootstrap principal has the permissions needed for the planned automation
- confirm any required admin consent has already been granted

### 5. Supabase

- create or confirm the base `Supabase` account/org manually
- create a personal access token
- decide the target project name for this repo
- decide the target region for the `Supabase` project
- decide the database password for project creation
- later automation will use these inputs to create or configure the project

Required bootstrap values:

- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_ORG_SLUG`
- `SUPABASE_DB_PASSWORD`
- `SUPABASE_PROJECT_NAME`

### 6. Vercel

- create or confirm the base `Vercel` account manually
- create a `Vercel` token
- decide whether the project belongs to your personal scope or a team scope
- if using a team, record the `teamId`
- decide the frontend project name

Required bootstrap values:

- `VERCEL_TOKEN`
- optional `VERCEL_TEAM_ID`
- optional `VERCEL_PROJECT_NAME`

### 7. Pinecone

- create or confirm the base `Pinecone` account manually
- create a `Pinecone` API key
- decide the first index name for test use
- decide the deployment region
- confirm the embedding dimension you intend to use

Recommended starting values for this repo:

- index name: `ingestra-ci`
- metric: `cosine`
- dimension: `384`

Required bootstrap values:

- `PINECONE_API_KEY`
- optional `PINECONE_INDEX_NAME`

### 8. GitHub Actions Secrets

Add these secrets before running the provision workflow:

- `PINECONE_API_KEY`
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_ORG_SLUG`
- `SUPABASE_DB_PASSWORD`
- `VERCEL_TOKEN`

Add these secrets when runtime smoke tests become available:

- `INGESTRA_UPLOAD_URL`
- `INGESTRA_SEARCH_URL`
- `INGESTRA_CHAT_URL`

Add these later if the deployment workflow will SSH to the VPS:

- `VPS_HOST`
- `VPS_USERNAME`
- `VPS_SSH_PRIVATE_KEY`

### 9. Local Operator Tools

Have these available on the machine you use to manage the repo:

- `git`
- `pwsh`
- `docker` if you want local parity testing
- optional `gh` CLI

## Bootstrap Acceptance

Bootstrap is complete when:

- the VPS exists and is reachable over `SSH`
- provider tokens have been created
- all required `GitHub Actions` secrets are populated
- the repo can pass:

```powershell
pwsh -File .\scripts\Test-BootstrapPrereqs.ps1 -Profile provision
```

## GitHub Secrets Contract

Current repo-owned automation expects these secrets when relevant:

- `SUPABASE_ACCESS_TOKEN`
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

## Local Validation

To validate the bootstrap contract locally:

```powershell
pwsh -File .\scripts\Test-BootstrapPrereqs.ps1 -Profile minimal
pwsh -File .\scripts\Test-BootstrapPrereqs.ps1 -Profile provision
```

## Pinecone Provisioning

To create or reset the default index locally:

```powershell
pwsh -File .\scripts\providers\Pinecone.ps1 `
  -Action EnsureIndex `
  -IndexName ingestra-ci `
  -Dimension 384 `
  -Metric cosine `
  -Cloud aws `
  -Region us-east-1
```

## Smoke Tests

When the runtime endpoints exist, validate them with:

```powershell
pwsh -File .\scripts\Invoke-IngestraSmokeTests.ps1
```
