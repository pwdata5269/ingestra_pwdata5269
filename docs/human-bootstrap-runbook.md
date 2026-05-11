# Human Bootstrap Runbook

## Purpose

Use this runbook to complete the one-time human setup required before repo automation can take over.

The goal is unambiguous execution:

- do the steps in order
- record the required values as you go
- do not move to the next step until the acceptance criteria for the current step are met

## Preconditions

Before starting, confirm you have:

- admin or owner access to the target `GitHub` repository
- permission to create or manage the target `Vercel` account or team
- permission to create or manage the target `Supabase` organization and project
- permission to create or manage the target `Pinecone` account and API key
- access to the required `Azure` tenant
- permission to create or manage the target VPS
- access to the DNS zone if a domain will be used

## Values To Record

Record these values securely during the runbook:

- `GitHub` repository URL
- default branch name
- VPS public IP address
- VPS SSH username
- VPS SSH method
- public DNS names
- `AZURE_TENANT_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_ORG_SLUG`
- `SUPABASE_PROJECT_NAME`
- `SUPABASE_DB_PASSWORD`
- `VERCEL_TOKEN`
- optional `VERCEL_TEAM_ID`
- optional `VERCEL_PROJECT_NAME`
- `PINECONE_API_KEY`
- optional `PINECONE_INDEX_NAME`
- where each secret is stored

## Ordered Steps

### Step 1. Confirm The GitHub Repository

Do this:

1. Confirm the target repository exists under the intended owner.
2. Confirm the default branch name, expected to be `main`.
3. Confirm `GitHub Actions` is enabled for the repository.
4. Confirm you can push to the repository from the operator machine.

Acceptance criteria:

- the repository exists
- the default branch is known
- the `Actions` tab is enabled
- you can push successfully from the operator machine

### Step 2. Create Or Confirm The VPS

Do this:

1. Create the VPS if it does not already exist.
2. Use `Ubuntu 24.04 LTS` if available, otherwise `Ubuntu 22.04 LTS`.
3. For the current test target, use:
   - `4 vCPU`
   - `8 GB RAM`
   - `75 GB NVMe`
4. Confirm the VPS is reachable over `SSH`.
5. Record the public IP address, SSH username, and SSH method.

Acceptance criteria:

- the VPS exists
- the VPS is reachable over `SSH`
- the IP address and login method are recorded

### Step 3. Decide DNS And Public URL Strategy

Do this:

1. Decide whether the environment will use direct IP access or a real domain/subdomain.
2. Prefer a real domain/subdomain for anything beyond disposable testing.
3. Decide the intended public hostname for:
   - `n8n`
   - optional parser service health endpoint
   - optional future MCP/API endpoint
4. Decide whether `HTTPS` will be terminated by `Nginx` or `Caddy`.
5. If using DNS, create the required DNS records.

Acceptance criteria:

- the public URL approach is decided
- the required hostnames are recorded
- DNS records exist if DNS is being used

### Step 4. Prepare Azure Bootstrap Inputs

Do this:

1. Confirm the target `Azure` tenant is the correct one.
2. Confirm the bootstrap identity or app registration still exists, or create it if required.
3. Record:
   - `AZURE_TENANT_ID`
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
4. Confirm required permissions and admin consent have been granted.

Acceptance criteria:

- the correct tenant is confirmed
- the bootstrap identity exists
- the Azure values are recorded
- admin consent status is known and complete

### Step 5. Create The Azure App Registration For Supabase Login

Do this:

1. Open `Microsoft Entra ID`.
2. Create an `App registration` for this project if it does not already exist.
3. Record:
   - `Application (client) ID`
   - `Directory (tenant) ID`
4. Create a client secret and record it immediately.
5. Add the Supabase callback URL as the redirect URI:
   - `https://<supabase-project-ref>.supabase.co/auth/v1/callback`
6. In `Supabase Auth`, configure the Azure provider with:
   - Azure client ID
   - Azure client secret
   - tenant URL:
     - `https://login.microsoftonline.com/<tenant-id>`

Acceptance criteria:

- the app registration exists
- the client secret exists and is recorded
- the Supabase callback URL is configured
- the values required by `Supabase Auth` are available

### Step 6. Create Or Confirm The Supabase Organization

Do this:

1. Log in to `Supabase`.
2. Create the base organization if it does not already exist.
3. Record the organization slug exactly.
4. Create a personal access token for management operations.
5. Decide:
   - the target project name
   - the target region
   - the database password for project creation
6. Record:
   - `SUPABASE_ACCESS_TOKEN`
   - `SUPABASE_ORG_SLUG`
   - `SUPABASE_PROJECT_NAME`
   - `SUPABASE_DB_PASSWORD`

Acceptance criteria:

- the organization exists
- the organization slug is recorded
- the personal access token exists
- the target project inputs are defined and recorded

### Step 7. Create Or Confirm The Vercel Account Or Team

Do this:

1. Log in to `Vercel`.
2. Create or confirm the correct account or team.
3. Create a token with project-management rights.
4. Decide whether the project belongs to personal scope or team scope.
5. If using a team, record the `teamId`.
6. Decide the intended Vercel project name.
7. Record:
   - `VERCEL_TOKEN`
   - optional `VERCEL_TEAM_ID`
   - optional `VERCEL_PROJECT_NAME`

Acceptance criteria:

- the correct Vercel scope exists
- the token exists
- the project scope decision is recorded
- the project name is defined

### Step 8. Create Or Confirm The Pinecone Account

Do this:

1. Log in to `Pinecone`.
2. Create or confirm the account.
3. Create an API key.
4. Choose `Integrated embedding` for the index strategy.
5. Choose the hosted embedding model `llama-text-embed-v2`.
6. Set the field map so the source text field is `chunk_text`.
7. Decide:
   - index name
   - region
   - metric
8. Use these required model-aligned values for this repo:
   - index name: `ingestra-ci`
   - embedding model: `llama-text-embed-v2`
   - field map source field: `chunk_text`
   - metric: `cosine`
   - dimension: `1024`
9. Record:
   - `PINECONE_API_KEY`
   - optional `PINECONE_INDEX_NAME`

Acceptance criteria:

- the Pinecone account is usable
- the API key exists
- the chosen embedding model is `llama-text-embed-v2`
- the canonical text field is `chunk_text`
- the initial index inputs are defined and recorded

### Step 9. Create The Vercel Project And Link The Repository

Do this:

1. Create the Vercel project if it does not already exist.
2. Link it to the correct `GitHub` repository.
3. Confirm the production branch is correct.
4. Confirm preview deployments are enabled as intended.
5. Record the project name, scope, and production branch.

Acceptance criteria:

- the Vercel project exists
- the correct repository is linked
- the production branch is correct
- preview deployment behavior is understood

### Step 10. Install The Supabase To Vercel Integration

Do this:

1. In `Supabase`, open `Integrations`.
2. Open `Vercel Integration`.
3. Authorize the correct Vercel account or team.
4. Link the correct Vercel project to the correct Supabase project.
5. Confirm which environments receive synced values:
   - `Production`
   - `Preview`
   - optional later `Development`
6. Verify that the correct Supabase values appear inside the linked Vercel project.

Acceptance criteria:

- Supabase and Vercel are linked correctly
- synced environment values are visible in the expected Vercel project

### Step 11. Decide Whether To Configure Supabase GitHub Connections

Do this:

1. Review whether the project needs Supabase-side repository awareness.
2. For this repo, the default answer is `no`.
3. Leave it unconfigured unless a concrete need appears.
4. Record the decision.

Acceptance criteria:

- the decision is explicit
- the project is not blocked on ambiguous optional integration work

### Step 12. Populate GitHub Actions Secrets

Do this:

1. Open the repository settings in `GitHub`.
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

Acceptance criteria:

- all current required secrets exist in `GitHub Actions`
- the later-only secrets are explicitly tracked as pending if not yet available

### Step 13. Validate The Repo Automation Contract

Do this:

1. Open the `Actions` tab in `GitHub`.
2. Run `validate.yml` manually.
3. Confirm the workflow completes successfully.
4. Confirm the dated HTML/XML report artifact is generated.

Acceptance criteria:

- `validate.yml` passes
- the report artifact is present
- there are no missing required provision secrets

### Step 14. Run The First Provisioning Workflow

Do this:

1. Run `provision-test.yml` manually.
2. Provide the intended `Pinecone` index name and dimension.
3. Decide whether to enable smoke tests yet.
4. Review the workflow output.

Acceptance criteria:

- the workflow completes successfully
- the `Pinecone` index is created or confirmed
- any failure is specific and actionable

## Bootstrap Exit Criteria

Human bootstrap is complete when all of the following are true:

- the repository exists and `GitHub Actions` is enabled
- the VPS exists and is reachable by `SSH`
- DNS and public URL decisions are complete
- the Azure bootstrap values are available
- the Azure app registration for `Supabase Auth` exists
- the `Supabase` organization exists and management token exists
- the `Vercel` account or team exists and the token exists
- the `Pinecone` API key exists
- the `Vercel` project exists and is linked to the correct repository
- the `Supabase` to `Vercel` integration is configured
- required `GitHub Actions` secrets are populated
- `validate.yml` passes
- `provision-test.yml` can run successfully

## Handoff To Automation

Once the exit criteria are met, ongoing setup and validation should move into repo-owned automation.

Current automation entrypoints are:

- `validate.yml`
- `provision-test.yml`
- `scripts\Test-BootstrapPrereqs.ps1`
- `scripts\providers\Pinecone.ps1`
- `scripts\Invoke-IngestraSmokeTests.ps1`
