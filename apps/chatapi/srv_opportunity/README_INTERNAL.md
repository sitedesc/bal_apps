# SchemedTalk – Internal Usage & Deployment

⚠️ This document contains **internal / operational information**.

For an overview of the project, architecture, and public demo, please read first:

➡️ **README.md**

---

## Purpose

This document describes:
- Local development setup
- CLI execution
- Deployment considerations
- Environment configuration

It is intended for developers maintaining or deploying the service.

---

## Local Development Setup

### Prerequisites

- Ballerina installed
  https://ballerina.io/learn/get-started/#install-ballerina

- Access to required API credentials (OpenFlex, Salesforce, etc.)

---

## Repository Layout

The service lives inside a Ballerina monorepo:

https://github.com/sitedesc/bal_apps

Path:
```
apps/chatapi
```

This structure supports:
- Shared connectors (e.g. Microsoft Teams client)
- Incremental migration toward componentized architectures
- Reuse across services

---

## CLI Execution

Example (country IT):

```bash
export OPENFLEX_TEST_AUTH='{ "IT": { "id": "...", "password": "..." } }'
export SALESFORCE_TEST_AUTH='{ "username": "...", "password": "...", "client_id": "...", "client_secret": "...", "grant_type": "password" }'

bal run -- IT ./SchemedTalks/Empty.json
```

This command:
- Compiles the service
- Executes the SchemedTalk in CLI mode
- Starts the HTTP service for Swagger execution

Stop with `Ctrl-C`.

---

## HTTP / Swagger Execution

Once running:
- Load Swagger UI
- Point it to `/openapi` or `/openapi_dev`
- Execute SchemedTalks via `POST /schemed_talks`

Authentication parameters must be provided explicitly in request bodies when using HTTP mode.

---

## Deployment Notes

- Ballerina produces a runnable JAR
- Alpine containers require the ZIP distribution of Ballerina
- Environment variables are used for API endpoints and credentials
- AWS configuration files are required in containerized environments

Refer to deployment scripts in the repository for examples.

---

## Error Diagnostics

When execution errors are truncated in `/schemed_talks` responses:

Use:
```
POST /schemed_talks_responses
```

This endpoint exposes the detailed execution trace of the last workflow.

---

## Status

This engine is actively evolving and used internally.
Public-facing demos are intentionally limited to safe, non-sensitive APIs.
