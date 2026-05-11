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

## Manual Integrations Checklist

These are the platform-side integrations worth setting up manually before deeper automation work continues.

### Supabase to Vercel

Do this now.

Reason:

- this integration is directly useful for the project
- it helps keep Supabase-related environment variables aligned in the connected `Vercel` project
- it reduces manual environment drift between hosted frontend deployments and the Supabase project

Manual steps:

1. Open your `Supabase` organization dashboard.
2. Open `Integrations`.
3. Choose `Vercel Integration`.
4. Authorize the correct `Vercel` account or team.
5. Link the intended `Vercel` project for this repo.
6. Confirm the environment variables are being synced to the correct Vercel project scope.
7. Confirm which environments are covered:
   - `Production`
   - `Preview`
   - optional later `Development`

What to verify afterward:

- the linked `Vercel` project is the correct one
- Supabase URL/public key values appear in the Vercel project settings
- branch or environment scoping behaves the way you expect for preview deployments

### Supabase GitHub Connections

Do not treat this as required right now.

Reason:

- the repo automation is already being driven by `GitHub Actions`
- the current scaffold does not depend on Supabase watching repository activity
- adding it now creates more moving parts without a clear delivery benefit

Use it only if you later decide you specifically want:

- Supabase-side awareness of repository activity
- tighter dashboard linkage between a Supabase project and a GitHub repository

Current recommendation:

- leave this unconfigured for now unless a concrete need appears

### GitHub Repository Settings

Do this now.

Manual steps:

1. Open the GitHub repo settings.
2. Confirm `Actions` is enabled.
3. Open `Secrets and variables` then `Actions`.
4. Add the required repository secrets:
   - `PINECONE_API_KEY`
   - `SUPABASE_ACCESS_TOKEN`
   - `SUPABASE_ORG_SLUG`
   - `SUPABASE_DB_PASSWORD`
   - `VERCEL_TOKEN`
5. Add runtime endpoint secrets later when those URLs exist:
   - `INGESTRA_UPLOAD_URL`
   - `INGESTRA_SEARCH_URL`
   - `INGESTRA_CHAT_URL`
6. If deployment will later use SSH to the VPS, add:
   - `VPS_HOST`
   - `VPS_USERNAME`
   - `VPS_SSH_PRIVATE_KEY`

What to verify afterward:

- `validate.yml` appears in the `Actions` tab
- `provision-test.yml` appears in the `Actions` tab
- `validate.yml` can be started manually
- `provision-test.yml` can be started manually

### Vercel Project Wiring

Do this now.

Manual steps:

1. Open the target `Vercel` account or team.
2. Confirm the correct GitHub repo is linked to the intended `Vercel` project.
3. Confirm the production branch is correct.
4. Check environment variables in the Vercel project settings.
5. If the Supabase integration is installed, confirm the synced values landed in the right environments.

What to verify afterward:

- the repo-to-project mapping is correct
- preview deployments will use the intended branch behavior
- production does not point at an old or wrong Supabase project

## Recommended Manual Order

Use this order:

1. Configure the `Vercel` integration in `Supabase`
2. Verify the target `Vercel` project linkage
3. Add required `GitHub Actions` secrets
4. Manually run `validate.yml`
5. Manually run `provision-test.yml` once the provision secrets are present

## Human Bootstrap Runbook

Purpose:

- this is the start-to-finish human implementation checklist that must be completed before the repo automation can be trusted to take over
- another engineer should be able to follow this without relying on chat history
- if a step is completed, record the outcome and any produced values immediately

Use this runbook for:

- first implementation of this project
- future rebuilds in a new account or tenant
- similar future projects that follow the same operating model

### Operating Principle

Treat the setup in two layers:

1. Human bootstrap
   - create the first trust boundaries
   - create accounts, orgs, tokens, projects, DNS, and access
2. Repo automation
   - validate secrets
   - provision supported resources
   - deploy
   - test
   - report

If a step requires:

- creating the first account or org
- accepting terms, plan, or billing
- granting OAuth consent
- proving domain ownership
- creating the first SSH or admin trust path

then it belongs in the human bootstrap layer.

## Start-To-Finish Checklist

Follow these sections in order.

### Phase 1. Create and Secure the GitHub Repository

Objective:

- create the canonical source repository where automation will live

Actions:

1. Create the GitHub repository under the intended owner.
2. Decide whether the repository is `private` or `public`.
3. Confirm the default branch name, expected to be `main`.
4. Enable `GitHub Actions` for the repository.
5. Confirm you can push to the repo from the intended operator machine.
6. If using a PAT, confirm the token has at least:
   - `repo`
   - `workflow`
7. Record:
   - repository URL
   - owning account or organization
   - default branch
   - chosen auth method for git push

Acceptance:

- the repo exists
- the operator can push a test commit
- the `Actions` tab is visible and enabled

### Phase 2. Create the VPS

Objective:

- create the runtime host for `n8n`, parser service, reverse proxy, and later deployment automation

Actions:

1. Create the VPS.
2. Use `Ubuntu 24.04 LTS` if available, otherwise `Ubuntu 22.04 LTS`.
3. For the current test target, use:
   - `4 vCPU`
   - `8 GB RAM`
   - `75 GB NVMe`
4. Record:
   - provider
   - region
   - public IP address
   - root or admin username
5. Confirm `SSH` access works.
6. Record how SSH auth is being done:
   - password temporarily
   - SSH key
7. If possible, move immediately to SSH key auth.

Acceptance:

- the VPS exists
- SSH access works from the operator machine
- the IP address and login method are recorded

### Phase 3. Decide DNS and Public URL Strategy

Objective:

- decide how external systems will reach the VPS-hosted services

Actions:

1. Decide whether this environment will use:
   - direct IP access temporarily
   - or a real domain/subdomain
2. Prefer a domain/subdomain for anything beyond disposable testing.
3. Decide the intended public hostname for:
   - `n8n`
   - optional parser health endpoint
   - optional future MCP/API endpoint
4. Decide which reverse proxy will terminate HTTPS:
   - `Nginx`
   - or `Caddy`
5. If using DNS, create the DNS records and record them.

Acceptance:

- the public URL plan is documented
- the expected service hostnames are recorded

### Phase 4. Prepare Azure Inputs

Objective:

- ensure Azure identity/bootstrap details are available for later configuration

Actions:

1. Confirm the target Azure tenant is the correct one.
2. Confirm the bootstrap app registration or service principal still exists.
3. Record:
   - `AZURE_TENANT_ID`
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
4. Confirm required permissions and admin consent are already granted.
5. Record any known callback or identity assumptions for the project.

Acceptance:

- all Azure bootstrap values are available
- permissions/consent status is known

### Phase 4A. Create the Azure App Registration for Supabase Login

Objective:

- create the Azure application that `Supabase Auth` will use for user sign-in

Actions:

1. Open `Microsoft Entra ID`.
2. Create a new `App registration` for this project.
3. Record:
   - `Application (client) ID`
   - `Directory (tenant) ID`
4. Create a client secret for the app registration.
5. Record the client secret value immediately.
6. Add the Supabase callback URL as the redirect URI:
   - `https://<supabase-project-ref>.supabase.co/auth/v1/callback`
7. In `Supabase Auth`, configure the Azure provider with:
   - Azure client ID
   - Azure client secret
   - tenant URL:
     - `https://login.microsoftonline.com/<tenant-id>`

Required outputs:

- Azure client ID
- Azure tenant ID
- Azure client secret
- confirmed Supabase callback URL

Permissions:

- for the sign-in app registration, keep permissions minimal
- do not treat broad Graph write permissions as required for this step
- only keep broad Graph application permissions on a separate bootstrap identity if Azure app-registration creation is going to be automated later

Acceptance:

- the Azure app registration exists
- the client secret exists and has been recorded
- the Supabase callback URL is configured
- the Azure provider values needed by Supabase are available

### Phase 5. Create or Confirm the Supabase Organization

Objective:

- establish the base Supabase tenancy needed before project automation can begin

Actions:

1. Log in to `Supabase`.
2. Create the base organization if it does not already exist.
3. Record the organization slug exactly.
4. Create a personal access token for management operations.
5. Decide:
   - target project name
   - target region
   - database password for project creation
6. Record:
   - `SUPABASE_ACCESS_TOKEN`
   - `SUPABASE_ORG_SLUG`
   - `SUPABASE_PROJECT_NAME`
   - `SUPABASE_DB_PASSWORD`

Acceptance:

- the organization exists
- the slug is recorded
- the management token exists
- the target project inputs are defined

### Phase 6. Create or Confirm the Vercel Account or Team

Objective:

- establish the Vercel tenancy for the frontend project

Actions:

1. Log in to `Vercel`.
2. Create or confirm the correct account or team.
3. Create a Vercel token with project-management rights.
4. Decide whether the project belongs to:
   - personal scope
   - team scope
5. If using a team, record the `teamId`.
6. Decide the intended Vercel project name.
7. Record:
   - `VERCEL_TOKEN`
   - optional `VERCEL_TEAM_ID`
   - optional `VERCEL_PROJECT_NAME`

Acceptance:

- the Vercel scope exists
- the token exists
- the intended project scope is known

### Phase 7. Create or Confirm the Pinecone Account

Objective:

- establish the vector store account and API key for automated index creation

Actions:

1. Log in to `Pinecone`.
2. Create or confirm the account.
3. Create an API key.
4. Decide:
   - index name
   - region
   - metric
   - dimension
5. Recommended starting values for this repo:
   - index name: `ingestra-ci`
   - metric: `cosine`
   - dimension: `384`
6. Record:
   - `PINECONE_API_KEY`
   - optional `PINECONE_INDEX_NAME`

Acceptance:

- the Pinecone API key exists
- the target index inputs are defined

### Phase 8. Create the Vercel Project and Link the Repo

Objective:

- ensure the frontend deployment target exists and is linked to the correct repo

Actions:

1. Create the Vercel project if it does not already exist.
2. Link it to the correct GitHub repository.
3. Confirm the production branch is correct.
4. Confirm preview deployments are enabled as expected.
5. Record:
   - project name
   - project scope
   - production branch

Acceptance:

- the Vercel project exists
- it is linked to the correct repo
- branch behavior is understood

### Phase 9. Install the Supabase to Vercel Integration

Objective:

- reduce manual environment drift between Supabase and the Vercel-hosted frontend

Actions:

1. In `Supabase`, open `Integrations`.
2. Open `Vercel Integration`.
3. Authorize the correct Vercel account or team.
4. Link the correct Vercel project to the correct Supabase project.
5. Confirm which environments receive synced values:
   - `Production`
   - `Preview`
   - optional later `Development`
6. Verify that the correct Supabase values appear inside the linked Vercel project.

Acceptance:

- Supabase and Vercel are linked correctly
- synced environment variables are visible in the expected Vercel project

### Phase 10. Decide Whether to Configure Supabase GitHub Connections

Objective:

- make an explicit decision instead of leaving this ambiguous

Actions:

1. Review whether the project currently needs Supabase-side repository awareness.
2. For this repo, default answer is `no`.
3. Leave this unconfigured unless a concrete use case appears.

Acceptance:

- the decision is explicit and recorded

### Phase 11. Populate GitHub Actions Secrets

Objective:

- provide the repo automation with the inputs it expects

Actions:

1. Open the GitHub repository settings.
2. Go to `Secrets and variables` then `Actions`.
3. Add these required secrets:
   - `PINECONE_API_KEY`
   - `SUPABASE_ACCESS_TOKEN`
   - `SUPABASE_ORG_SLUG`
   - `SUPABASE_DB_PASSWORD`
   - `VERCEL_TOKEN`
4. Add these later when runtime endpoints exist:
   - `INGESTRA_UPLOAD_URL`
   - `INGESTRA_SEARCH_URL`
   - `INGESTRA_CHAT_URL`
5. Add these later when VPS deployment automation is introduced:
   - `VPS_HOST`
   - `VPS_USERNAME`
   - `VPS_SSH_PRIVATE_KEY`

Acceptance:

- all current required secrets are present in GitHub

### Phase 12. Validate the Repo Automation Contract

Objective:

- prove that the repo can see the minimum required inputs before provisioning starts

Actions:

1. Open the `Actions` tab in GitHub.
2. Run `validate.yml` manually.
3. Confirm the workflow completes successfully.
4. Download the dated HTML/XML report artifact if desired.

Acceptance:

- `validate.yml` passes
- the report artifact is generated

### Phase 13. Run the First Provisioning Workflow

Objective:

- prove that the repo can perform the first supported external operation

Actions:

1. Run `provision-test.yml` manually.
2. Provide the intended `Pinecone` index name and dimension inputs.
3. Decide whether to enable smoke tests yet.
4. Review the workflow output and any artifact/report evidence.

Acceptance:

- the workflow completes
- the Pinecone index is created or confirmed
- failures, if any, are specific and actionable

## What Must Be Recorded During Bootstrap

Another engineer should not have to rediscover these values.

Record and store securely:

- GitHub repo URL
- default branch
- VPS IP address
- SSH username
- SSH method
- DNS names
- Azure tenant/client details
- Supabase org slug
- Supabase project name
- Supabase region
- Vercel project name
- Vercel scope
- Pinecone index name
- Pinecone region
- where each secret is stored

## Bootstrap Exit Criteria

Human bootstrap is complete when all of the following are true:

- the repo exists and can run Actions
- the VPS exists and is reachable by SSH
- DNS/public URL decisions are made
- Azure bootstrap values are available
- Supabase org and token exist
- Vercel account/team and token exist
- Pinecone API key exists
- the Vercel project exists and is linked to the repo
- the Supabase to Vercel integration is configured
- required GitHub Actions secrets are populated
- `validate.yml` passes
- `provision-test.yml` can be run successfully

## Reuse Guidance For Future Projects

For future projects, copy this runbook and only replace:

- provider names
- project names
- regions
- runtime topology
- required secrets list

Do not skip the structure:

1. source control
2. runtime host
3. DNS
4. identity inputs
5. managed service orgs/accounts
6. project wiring
7. secret population
8. validation
9. first provisioning run

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
