# API Workflow Orchestration with Ballerina (SchemedTalk)

## Overview

This project demonstrates a **modular API workflow orchestration engine** built with **Ballerina**, designed to model, execute, and observe complex business workflows across heterogeneous systems using typed API calls.

Workflows are defined as structured JSON documents called **SchemedTalks**. Each SchemedTalk describes a sequence of API interactions (authentication, data retrieval, creation, validation, etc.) that are executed step by step by the orchestration engine.

The project focuses on:
- API-first design
- Microservice-friendly orchestration
- Strong typing and validation
- Observability and debuggability
- Incremental migration from legacy integration patterns

This repository contains a **public demo-ready subset** of an internal orchestration engine used in production contexts.

Repository:
https://github.com/sitedesc/bal_apps/tree/main/apps/chatapi

---

## Key Concepts

### SchemedTalk
A SchemedTalk is a JSON-defined workflow composed of typed requests and control steps:
- HTTP requests (GET, POST, PUT, PATCH)
- Managed requests (Salesforce, OpenFlex, OpenAI, etc.)
- Data memorization using JSONPath
- Conditional and comparison primitives
- Documentation steps for observability

SchemedTalks are:
- Declarative
- Serializable
- Executable via CLI or HTTP
- Inspectable step-by-step

### Typed API Requests
Each request type is backed by a Ballerina `record`:
- Automatic JSON → type validation
- Explicit API routes and semantics
- Reduced runtime errors
- Clear contract between workflow and execution engine

### Data Reuse & JSONPath
Responses can be queried using JSONPath expressions and stored in workflow memory for reuse in subsequent steps.

Online tools:
- JSON Editor: https://json-editor.github.io/json-editor/
- JSONPath evaluator: https://jsonpath.com/

---

## Demo: OpenAI-based Workflow

The demo SchemedTalk below:
1. Calls the OpenAI API
2. Memorizes the generated text
3. Re-displays it using a dynamic expression

```json
[
  {
    "type": "SchemedTalkDoc",
    "description": "Demo SchemedTalk showing OpenAI call followed by JSONPath-based memory extraction."
  },
  {
    "type": "OARequest",
    "prompt": "Explain in one short paragraph what microservices are and why API orchestration matters.",
    "prePromptFile": null
  },
  {
    "type": "Memorize",
    "asWhat": {
      "microservices_definition": "jsonpath:$.oaResponse"
    }
  },
  {
    "type": "SchemedTalkDoc",
    "description": "<?memory:microservices_definition?>"
  }
]
```

This demo is executable directly via **Swagger UI**.

---

## API Usage

### Execute a SchemedTalk

`POST /schemed_talks`

- Body: array of SchemedTalk steps (JSON)
- Response: execution trace and responses

### Retrieve detailed execution errors

`POST /schemed_talks_responses`

This endpoint exposes detailed execution diagnostics when a workflow fails (timeouts, JSONPath errors, type mismatches).

---

## Architecture Overview

- Language: Ballerina
- Execution model: sequential orchestration
- Transport: HTTP / REST
- Deployment: container-ready
- Repo structure: monorepo with reusable packages/connectors

The engine is designed to evolve toward:
- Nested workflows
- Conditional branching
- Retry and compensation logic
- AI-assisted workflow generation

---

## Why It Matters

### For API & Microservices Engineers
- Explicit orchestration instead of implicit coupling
- Strong typing for integration logic
- Testable, observable workflows
- Reduced boilerplate for cross-service coordination

### For Platform & Integration Teams
- Faster integration cycles
- Lower operational risk
- Clear separation between workflow definition and execution

---

## Roadmap

- Conditional execution support
- Error handling primitives
- Public connector examples (GitHub, Google APIs)
- Natural-language → SchemedTalk generation

---

## Internal Documentation

For deployment, credentials, CLI usage, and operational details, see:

➡️ **README_INTERNAL.md**
