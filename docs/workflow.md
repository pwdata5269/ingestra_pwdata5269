# Workflow

## Purpose

This repo owns the automation workflow around the `Ingestra` platform.

## CI Workflow Layers

### Validate

- run `Pester`
- use `Pester 5` syntax in repo tests because CI installs a current `Pester` release
- validate secret-name contracts
- fail before any external mutation if the bootstrap contract is incomplete
- run manually, on pushes to `main` or `master`, and on pull requests
- emit one dated `JUnit` XML file and one dated HTML report for each workflow invocation
- keep per-test detail inside the invocation report rather than creating a separate HTML file per test

### Provision

- create the `Supabase` project
- capture the resulting `Supabase` project ref
- create or update the Azure app registration for `Supabase` login
- emit a fresh usable Azure client secret for the current run
- for schema application, use the stored `SUPABASE_DB_URL` session-pooler connection string with `psql`
- create or confirm the vector index in `Pinecone`
- create or confirm the `Vercel` project
- create or confirm the `Vercel` GitHub repository link and production branch mapping after `Vercel` has already been granted access to the repository
- resolve the `Vercel` browser URLs and configure `Supabase` browser auth
- generate a static `runtime-config.js` file for the minimal auth harness during CI
- deploy the frontend to `Vercel` directly from `GitHub Actions`
- verify the deployed harness can complete Azure login through `Supabase`, and ensure the workflow records the deployment URL cleanly
- later: apply remaining schema and environment settings

### Test

- run HTTP smoke tests for upload, retrieval, and chat
- run isolated schema-application validation against `Supabase` using checked-in SQL migrations and `psql`
- later: run fuller integration tests against seeded fixtures

## Vector Provider Contract

The solution should treat vector storage through a provider contract with operations such as:

- initialize store
- reset store
- upsert document chunks
- delete document vectors
- search document chunks
- test vector-store health

The first implemented provider is `Pinecone`.

## Build Philosophy

Do not rebuild the entire external estate on every run.

Preferred pattern:

- bootstrap the provider account once
- create environment-specific resources through automation
- recreate disposable test resources where it is cheap and safe
- for the minimal `Vercel` auth harness on the `Hobby` plan, prefer CI-driven deployments over relying on Git-triggered private-repo collaborator flows
