# Workflow

## Purpose

This repo owns the automation workflow around the `Ingestra` platform.

## CI Workflow Layers

### Validate

- run `Pester`
- validate secret-name contracts
- fail before any external mutation if the bootstrap contract is incomplete

### Provision

- create or confirm the vector index in `Pinecone`
- later: create/configure the `Supabase` and `Vercel` projects
- later: apply schema and environment settings

### Test

- run HTTP smoke tests for upload, retrieval, and chat
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
