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
- `Vercel` project creation and environment-variable wiring
- `n8n` deployment validation

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
9. apply provider-specific settings
10. run smoke tests when enabled
11. publish logs, summaries, and test reports

## Near-Term Sequence

Use this order for the next implementation and verification work:

1. implement `Vercel` project automation
2. create a minimal frontend auth test page
3. link the frontend to `Supabase` auth
4. run an end-to-end Azure login test

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
- later apply remaining post-create configuration
- later apply schema, auth, and environment-related setup

Current proven result:

- `EnsureProject` has successfully created the configured `Supabase` project in `GitHub Actions`
- current project ref: `xshawwxhqjjbemptekjk`
- Azure login is now visibly enabled in the live `Supabase` project

### Vercel

Automation should:

- create the target project
- apply project-level configuration
- later wire required environment variables

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

- `Supabase` post-create configuration is not yet implemented
- `Vercel` project automation is not implemented
- the current `Pinecone` script does not yet consume the JSON config file
- integrated-embedding `Pinecone` index creation is not yet scripted
- `n8n` automation is not yet implemented
- full end-to-end upload, retrieval, and chat fixtures are not yet implemented

## Change Control

When changing project-level automation behavior:

1. update `config/automation-config.json`
2. update this runbook if operator guidance or intent changed
3. update scripts to consume the config where required
