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
- `SUPABASE_DB_PASSWORD`
- `VERCEL_TOKEN`
- optional `VERCEL_TEAM_ID`
- `PINECONE_API_KEY`
- where each secret is stored

## Ordered Steps

## Phase 1. Account And Org Bootstrap

This phase establishes the provider and repository trust boundary.

At the end of this phase, you should have:

- the `GitHub` repository ready for Actions
- the required `Azure` bootstrap values
- the required `Supabase` org-level inputs
- the required `Vercel` account or team inputs
- the required `Pinecone` account input
- the required `GitHub Actions` repository secrets

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

### Step 2. Prepare Azure Bootstrap Inputs

Do this:

1. Confirm the target `Azure` tenant is the correct one.
2. Confirm the bootstrap identity or app registration still exists, or create it if required.
3. If the bootstrap identity will create or manage the later `Supabase` OAuth app registration through automation, confirm it has the required temporary elevated Microsoft Graph application permissions.
4. Current accepted bootstrap pattern for this repo:
   - bootstrap app registration: `codex_bootstrap`
   - delegated permission: `User.Read`
   - application permission: `Application.ReadWrite.All`
   - application permission: `Directory.ReadWrite.All`
5. Record that these elevated application permissions are bootstrap permissions, not permanent runtime permissions.
6. Plan to remove or reduce those elevated permissions after the required Azure app-registration work is complete.
7. Record:
   - `AZURE_TENANT_ID`
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
8. Confirm required permissions and admin consent have been granted.

Acceptance criteria:

- the correct tenant is confirmed
- the bootstrap identity exists
- the bootstrap app registration permission model is recorded
- the Azure values are recorded
- admin consent status is known and complete

### Step 3. Create Or Confirm The Supabase Organization

Do this:

1. Log in to `Supabase`.
2. Create the base organization if it does not already exist.
3. Record the organization slug exactly.
4. Create a personal access token for management operations.
5. Decide the project database password that automation will use when it creates the project.
6. Record:
   - `SUPABASE_ACCESS_TOKEN`
   - `SUPABASE_ORG_SLUG`
   - `SUPABASE_DB_PASSWORD`

Acceptance criteria:

- the organization exists
- the organization slug is recorded
- the personal access token exists
- the org-level bootstrap inputs and required automation secret are defined and recorded

### Step 4. Create Or Confirm The Vercel Account Or Team

Do this:

1. Log in to `Vercel`.
2. Create or confirm the correct account or team.
3. Create a token with project-management rights.
4. Decide whether automation will target personal scope or team scope.
5. If using a team, record the `teamId`.
6. Record:
   - `VERCEL_TOKEN`
   - optional `VERCEL_TEAM_ID`

Acceptance criteria:

- the correct Vercel scope exists
- the token exists
- the automation target scope is recorded

### Step 5. Create Or Confirm The Pinecone Account

Do this:

1. Log in to `Pinecone`.
2. Create or confirm the account.
3. Create an API key.
4. Record:
   - `PINECONE_API_KEY`

Acceptance criteria:

- the Pinecone account is usable
- the API key exists
- the account-level bootstrap input is recorded

### Step 6. Decide Whether To Configure Supabase GitHub Connections

Do this:

1. Review whether the project needs Supabase-side repository awareness.
2. For this repo, the default answer is `no`.
3. Leave it unconfigured unless a concrete need appears.
4. Record the decision.

Acceptance criteria:

- the decision is explicit
- the project is not blocked on ambiguous optional integration work

### Step 7. Populate GitHub Actions Secrets

Do this:

1. Open the repository settings in `GitHub`.
2. Go to `Secrets and variables` then `Actions`.
3. Use `Repository secrets` for the current workflow contract because the repo reads these values through `secrets.*`.
4. Add these required Repository secrets:
   - `AZURE_TENANT_ID`
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `PINECONE_API_KEY`
   - `SUPABASE_ACCESS_TOKEN`
   - `SUPABASE_ORG_SLUG`
   - `SUPABASE_DB_PASSWORD`
   - `VERCEL_TOKEN`
5. Use `Variables` only for non-sensitive values if you later want central non-secret config, for example:
   - `VERCEL_TEAM_ID`
   - later non-secret automation config values if needed
6. Do not use `Environment secrets` unless the repo later introduces distinct GitHub environments such as `dev`, `test`, or `prod`.

Acceptance criteria:

- all current required secrets exist in `GitHub Actions`

### Step 8. Validate The Account And Org Bootstrap Contract

Do this:

1. Open the `Actions` tab in `GitHub`.
2. Run `validate.yml` manually.
3. Confirm the workflow completes successfully.
4. Confirm the dated HTML/XML report artifact is generated.

Acceptance criteria:

- `validate.yml` passes
- the report artifact is present
- there are no missing required current bootstrap secrets

## Phase 1 Exit Criteria

Phase 1 is complete when all of the following are true:

- the repository exists and `GitHub Actions` is enabled
- the Azure bootstrap values are available
- the `Supabase` organization exists and management token exists
- the `Vercel` account or team exists and the token exists
- the `Pinecone` API key exists
- required `GitHub Actions` repository secrets are populated
- `validate.yml` passes

At this point, provider account and org bootstrap is complete and project-level automation can be exercised.

## Phase 2. Runtime Host And n8n Preparation

This phase prepares the VPS-hosted runtime estate after the provider/org bootstrap has been validated.

### Step 11. Create Or Confirm The VPS

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

### Step 12. Decide DNS And Public URL Strategy

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

## Bootstrap Exit Criteria

Human bootstrap is complete when all of the following are true:

- the repository exists and `GitHub Actions` is enabled
- the Azure bootstrap values are available
- the `Supabase` organization exists and management token exists
- the `Vercel` account or team exists and the token exists
- the `Pinecone` API key exists
- required `GitHub Actions` secrets are populated
- `validate.yml` passes
- the VPS exists and is reachable by `SSH`
- DNS and public URL decisions are complete

## Bootstrap Cleanup

After the Azure bootstrap app registration has completed the required app-registration work, review whether its elevated Microsoft Graph application permissions are still needed.

Preferred outcome:

- remove elevated permissions that are no longer required
- or retire the bootstrap app registration entirely if it is no longer needed

## Handoff To Automation

Once the exit criteria are met, ongoing setup and validation should move into repo-owned automation.

Current automation entrypoints are:

- `validate.yml`
- `provision-test.yml`
- `scripts\Test-BootstrapPrereqs.ps1`
- `scripts\providers\Pinecone.ps1`
- `scripts\Invoke-IngestraSmokeTests.ps1`
