# ingestra_pwdata5269

Assumptions:
- This repository is the CI/CD-driven rebuild of the existing `Ingestra` solution.
- `Pinecone` is the default vector backend for this repo.
- `Qdrant` compatibility is a later adapter, not the first delivery target.
- One-time provider bootstrap still exists for account/org creation and token issuance.

## Purpose

This repo exists to make `Ingestra` build, configure, validate, and test in a repeatable way using:

- `GitHub Actions` for orchestration
- `PowerShell` for service configuration and test execution
- `Pester` for automation validation

## Scope

The target phase-1 stack is:

- static frontend deployed to `Vercel`
- `Supabase` for auth and metadata
- `n8n` for ingestion, retrieval, and chat orchestration
- `Pinecone` for vector storage
- optional parser service for page-aware PDF extraction

## Delivery Model

Manual bootstrap is limited to what cannot be established safely before authentication exists, for example:

- base `Supabase` account/org
- base `Vercel` account/team if needed
- provider tokens and secrets
- any human consent steps in `Azure`

Everything after that should be scriptable and CI-driven.

## Repository Layout

- [spec.md](/C:/Projects/ingestra_pwdata5269/spec.md)
- [tasks.md](/C:/Projects/ingestra_pwdata5269/tasks.md)
- [docs/setup.md](/C:/Projects/ingestra_pwdata5269/docs/setup.md)
- [docs/workflow.md](/C:/Projects/ingestra_pwdata5269/docs/workflow.md)
- [docs/observability.md](/C:/Projects/ingestra_pwdata5269/docs/observability.md)
- [docs/decisions.md](/C:/Projects/ingestra_pwdata5269/docs/decisions.md)
- [docs/process.md](/C:/Projects/ingestra_pwdata5269/docs/process.md)
- [scripts/Test-BootstrapPrereqs.ps1](/C:/Projects/ingestra_pwdata5269/scripts/Test-BootstrapPrereqs.ps1)
- [scripts/Invoke-IngestraSmokeTests.ps1](/C:/Projects/ingestra_pwdata5269/scripts/Invoke-IngestraSmokeTests.ps1)
- [scripts/providers/Pinecone.ps1](/C:/Projects/ingestra_pwdata5269/scripts/providers/Pinecone.ps1)
- [scripts/providers/Supabase.ps1](/C:/Projects/ingestra_pwdata5269/scripts/providers/Supabase.ps1)
- [tests/Ingestra.Common.Tests.ps1](/C:/Projects/ingestra_pwdata5269/tests/Ingestra.Common.Tests.ps1)

## First Workflows

- `validate.yml`
  - lints the automation contract through `Pester`
  - validates required secret names for selected modes

- `provision-test.yml`
  - manually triggered
  - validates bootstrap secrets
  - can create or reset the `Pinecone` index
  - can run smoke tests against provisioned endpoints

## Current State

This scaffold is intentionally provider-shaped, not feature-complete. It establishes the repo contract for:

- documentation
- script boundaries
- CI entrypoints
- secret naming
- `Pinecone` provisioning
- smoke-test orchestration

The next slice is to implement the actual `Supabase`, `Vercel`, and `n8n` configuration steps behind the existing script boundaries.
