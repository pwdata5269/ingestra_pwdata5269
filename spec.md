# Project Specification

## Purpose

`ingestra_cicd` is a repeatable build and delivery repository for the `Ingestra` document ingestion platform.

This repo replaces ad hoc environment setup with:

- documented bootstrap boundaries
- PowerShell-driven configuration
- GitHub Actions orchestration
- automated validation and smoke testing

## Core Architecture

- frontend: static browser app deployed to `Vercel`
- auth and metadata: `Supabase`
- orchestration: `n8n`
- vector store: `Pinecone`
- parser: optional PDF parser service for page-aware ingestion

## Design Principle

The solution should be homogeneous at the workflow contract layer, not at the vendor API layer.

That means:

- document lifecycle stays stable
- ingestion/retrieval contracts stay stable
- tests stay stable
- provider differences are isolated in adapters

## Functional Goals

- authenticated users can upload supported documents
- the system detects new, changed, and unchanged content
- metadata is stored in `Supabase`
- vectors are stored in `Pinecone`
- retrieval and grounded chat operate through `n8n`
- CI can validate the automation contract and run smoke tests

## Delivery Goals

- minimize human steps after initial provider bootstrap
- use `PowerShell` for configuration wherever an API or CLI allows it
- keep scripts idempotent where practical
- expose a clear acceptance path for each environment

## Manual Bootstrap Boundary

Manual once:

- create the base `Supabase` org/account if it does not already exist
- create the base `Vercel` account/team if required
- create or retrieve provider access tokens
- complete any `Azure` admin-consent or tenant-level approvals

Automated afterward:

- create or configure the `Supabase` project
- create or configure the `Vercel` project
- create or reset the `Pinecone` index
- validate runtime secrets
- run smoke and integration tests

## Acceptance Criteria

The repo is successful when:

- `GitHub Actions` can validate required bootstrap secrets
- `PowerShell` scripts can provision the default `Pinecone` index
- smoke tests can validate the configured HTTP surfaces
- documentation clearly separates manual bootstrap from automated delivery
- the vector-provider contract is explicit enough for a later `Qdrant` adapter
