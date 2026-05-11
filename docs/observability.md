# Observability

## Goals

- fail fast on missing bootstrap inputs
- produce readable `GitHub Actions` logs and summaries
- separate provisioning failures from runtime failures
- provide simple smoke-test evidence

## Minimum Coverage

- `Pester` output in CI
- explicit missing-secret reporting
- provisioning step logs for `Pinecone`
- smoke-test pass/fail output for configured endpoints
- workflow failures should distinguish test-syntax issues from real infrastructure or secret failures

## Reporting Pattern

- local scripts write concise console output
- CI jobs append high-signal summaries to `GITHUB_STEP_SUMMARY` when available
- future integration tests should publish artifacts for request/response evidence
