# Automation Operations Runbook

## Purpose

This runbook defines the repo-owned automation layer for `Ingestra`.

It starts after human bootstrap is complete and covers:

- what automation is expected to create
- which inputs automation requires
- where configuration lives
- how automation should be operated and extended

## Automation Boundary

Human bootstrap should establish only the trust and access prerequisites:

- provider accounts, orgs, or teams
- tokens, API keys, and secrets
- Azure consent and identity prerequisites
- GitHub repository and Actions access
- `Vercel` GitHub authorization so the target repository is visible for connection

Project-level resources belong to automation wherever feasible.

All automation steps should be idempotent.

For this repo, idempotent means:

- do not create duplicate resources when the intended resource already exists
- repair or reconcile missing required configuration on existing resources
- produce fresh transient values when required and not recoverable, for example a newly created client secret
- allow reruns to converge on the intended end state

For this repo, that means automation should own creation or confirmation of:

- the `Supabase` project
- the Azure app registration for `Supabase` login once the `Supabase` project ref exists
- the `Vercel` project
- the `Vercel` GitHub repository link and production branch mapping after the repository has been authorized and exposed to `Vercel`
- the `Pinecone` index
- later `n8n` deployment and configuration steps

## Inputs

Automation depends on two input types:

- secrets in `GitHub Actions`
- machine-readable settings in `config/automation-config.json`

### Secrets

Current required repository secrets:

- `AZURE_TENANT_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `PINECONE_API_KEY`
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_DB_URL`
- `SUPABASE_ORG_SLUG`
- `SUPABASE_DB_PASSWORD`
- `VERCEL_TOKEN`

Later or optional repository secrets:

- `INGESTRA_UPLOAD_URL`
- `INGESTRA_SEARCH_URL`
- `INGESTRA_CHAT_URL`
- `VPS_HOST`
- `VPS_USERNAME`
- `VPS_SSH_PRIVATE_KEY`

### Configuration File

The canonical automation settings file is:

- [automation-config.json](/C:/Projects/ingestra_pwdata5269/config/automation-config.json)

Use the JSON file for exact resource settings such as:

- project names
- regions
- provider scope choices
- feature flags
- Pinecone embedding and index settings

If the runbook and the JSON ever disagree, the JSON is the automation source of truth.

## Configuration Model

The JSON file is organized by provider or system boundary:

- `azure`
- `supabase`
- `vercel`
- `pinecone`
- `n8n`

Each section should contain only values automation needs to create or configure resources.

## Current Automation Entry Points

Current repo entry points:

- `validate.yml`
- `provision-test.yml`
- `scripts/providers/Azure.ps1`
- `scripts/providers/Supabase.ps1`
- `scripts/Test-BootstrapPrereqs.ps1`
- `scripts/providers/Pinecone.ps1`
- `scripts/Invoke-IngestraSmokeTests.ps1`

Later provider entry points should be added for:

- `Supabase` project creation and post-create configuration
- `Vercel` project creation, repo linkage, deployment protection, and CI-driven deployment
- `n8n` deployment validation

Current checked-in schema source for later `Supabase` post-create automation:

- [20260512213000_initial_ingestra_tables.sql](/C:/Projects/ingestra_pwdata5269/supabase/migrations/20260512213000_initial_ingestra_tables.sql)

## Execution Flow

The intended automation flow is:

1. validate required secrets
2. load `config/automation-config.json`
3. create the `Supabase` project
4. capture the resulting `Supabase` project ref and URL
5. create or update the Azure app registration for `Supabase` login
6. configure `Supabase` auth to use the Azure sign-in app
7. create or confirm the `Pinecone` index
8. create or confirm the `Vercel` project
9. create or confirm the `Vercel` GitHub repo link and production branch mapping after human bootstrap has granted `Vercel` access to the repository
10. resolve frontend browser URLs and configure `Supabase` browser auth settings
11. generate the static frontend runtime config consumed by the auth harness
12. deploy the frontend to `Vercel` from `GitHub Actions`
13. run smoke tests when enabled
14. publish logs, summaries, and test reports

## Near-Term Sequence

Use this order for the next implementation and verification work:

1. implement `Vercel` project automation
2. ensure the GitHub repository is linked to the `Vercel` project, assuming `Vercel` has already been granted access to that repository
3. verify the CI-driven static frontend deployment path on `Vercel`
4. verify the minimal frontend auth page is reachable
5. prove Azure login end to end through the deployed harness

## Provider Intent

### Azure

Automation should:

- use the bootstrap Azure identity from `GitHub Actions` secrets
- create or update the Azure app registration used for `Supabase` login
- apply the correct redirect URI only after the `Supabase` project ref exists
- keep the Azure sign-in app registration minimal for login use
- ensure a usable client secret is available for the current automation run
- support later cleanup or reduction of bootstrap-only elevated permissions

Current proven result:

- `EnsureSupabaseLoginApp` has successfully created or updated the Azure sign-in app in `GitHub Actions`
- reruns now create a fresh usable client secret for the current run

### Supabase

Automation should:

- create the target project
- preserve idempotent behavior through `EnsureProject`
- expose the resulting project ref needed by the Azure redirect URI
- configure Azure auth to use the generated Azure sign-in app
- apply checked-in SQL schema files for post-create configuration
- use `SUPABASE_DB_URL` as the current source of truth for the session-pooler connection string when applying schema migrations
- create the initial internal tables:
  - `pinecone_records`
  - `retrieval_result_logs`
- enable RLS on those tables as part of the initial schema
- avoid broad `anon` read policies by default and rely on backend or service-role access unless stricter client access rules are intentionally added later
- later apply remaining post-create configuration
- later apply schema, auth, and environment-related setup

Current proven result:

- `EnsureProject` has successfully created the configured `Supabase` project in `GitHub Actions`
- current project ref: `xshawwxhqjjbemptekjk`
- Azure login is now visibly enabled in the live `Supabase` project
- the current schema-automation contract uses a stored session-pooler connection string in `SUPABASE_DB_URL`

Current declared next schema target:

- [20260512213000_initial_ingestra_tables.sql](/C:/Projects/ingestra_pwdata5269/supabase/migrations/20260512213000_initial_ingestra_tables.sql)
- `pinecone_records`
  - `id`
  - `document_id`
  - `document_name`
  - `document_type`
  - `collection`
  - `hash`
  - `uploaded_by`
  - `uploaded_at`
- `retrieval_result_logs`
  - `id`
  - `request_id`
  - `workflow_type`
  - `query_text`
  - `provider`
  - `model`
  - `collection`
  - `result_index`
  - `document_id`
  - `doc_name`
  - `page_number`
  - `score`
  - `created_at`

### Vercel

Automation should:

- create the target project
- ensure the correct GitHub repository is linked to the project after `Vercel` can already see that repository
- ensure the correct production branch is configured
- configure deployment protection so the production auth harness stays reachable while previews remain protected
- deploy the minimal auth harness from `GitHub Actions`
- provide runtime configuration to the harness through a generated static `runtime-config.js` file during CI

Current proven result:

- `EnsureProject` has successfully created or confirmed the configured `Vercel` project in `GitHub Actions`
- `EnsureProjectLink` has successfully linked the configured GitHub repository and production branch in `GitHub Actions`
- the minimal static auth harness has deployed successfully to `Vercel`
- Azure login through `Supabase` is manually proven through the deployed `Vercel` auth harness
- repeated visits to the harness may silently restore the existing session instead of forcing a fresh Azure prompt

### Pinecone

Automation should:

- create or confirm the target index
- use the configured embedding/index settings from the JSON file

### n8n

Automation is expected later, once the deployment model is finalized.

## Acceptance Criteria

Automation is in the intended state when:

- human bootstrap is limited to org/account/token/access setup
- project-level resources are created by scripts or CI
- automation behavior is driven by declared secrets and JSON config
- reruns are idempotent and converge on the intended state
- failures are specific and actionable

## Known Gaps

Current gaps:

- `Supabase` post-create schema application still needs to be proven end to end in `GitHub Actions`
- `Vercel` GitHub repository authorization remains a one-time manual prerequisite
- the current `Pinecone` script does not yet consume the JSON config file
- integrated-embedding `Pinecone` index creation is not yet scripted
- `n8n` automation is not yet implemented
- full end-to-end upload, retrieval, and chat fixtures are not yet implemented

## Auth Harness Notes

Expected browser behavior for the current `Vercel` auth harness:

- if a valid `Supabase` session already exists in the browser, the page may restore it immediately without redirecting to Azure
- if the local `Supabase` session has been cleared but the browser still has an active Azure session, a new sign-in attempt may complete silently through Azure SSO
- use the harness `Sign out` action to clear the local `Supabase` session
- if a true reauthentication prompt is required, additional OAuth prompt parameters or full Microsoft session logout should be added deliberately rather than assumed by default

Security note:

- silent sign-in is expected SSO behavior, not by itself a defect
- local `Supabase` session persistence and upstream Azure/Microsoft SSO persistence are separate layers
- if stricter behavior is required, treat it as an explicit policy choice:
  - shorten session lifetime
  - require reauthentication for sensitive actions
  - add a test or admin mode that requests `prompt=login` or `prompt=select_account`

## Change Control

When changing project-level automation behavior:

1. update `config/automation-config.json`
2. update this runbook if operator guidance or intent changed
3. update scripts to consume the config where required
