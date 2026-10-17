# Lifora — Backend Services Engineering Instructions

This directory contains Lifora's Jac server-side service boundary.

Read the repository root AGENTS.md first.

Also read before coding:

- docs/PRODUCT.md
- docs/ARCHITECTURE.md
- docs/CONTRACTS.md
- docs/DEMO.md

Use the current Jac version installed in this repository.

Never guess unfamiliar Jac syntax.

Use the current Jac guides and compiler as the source of truth.

---

# Ownership

The services directory has TWO logical owners.

## Member 1 owns state-related services

Expected responsibilities include:

- persistent student state
- task state
- budget / expense state
- available-time state
- demo seed state
- StudentSnapshot creation
- state mutation operations

Likely files may include:

- state.sv.jac
- tasks.sv.jac
- finance.sv.jac
- snapshot.sv.jac

Exact filenames may change if current Jac conventions suggest a cleaner
structure.

## Member 2 owns the planning/intelligence service boundary

Member 2 owns:

- planning.sv.jac

The planning service connects StudentSnapshot to the agent pipeline and
returns CoordinatorResult.

Member 1 must not implement agent reasoning inside state services.

Member 2 must not redesign persistent state inside planning.sv.jac.

---

# Member 1 Goal

Member 1 builds Lifora's memory.

The public integration output is:

StudentSnapshot

Other modules should not need to understand internal persistence or graph
implementation details.

Conceptual flow:

Persistent State
    ->
StudentSnapshot
    ->
Agent Pipeline

---

# Minimal Persistent Domain Model

Implement only the state required by the hackathon demo.

Required concepts:

## Profile

- name
- life stage

## AcademicTask

- id
- title
- deadline
- progress
- estimated remaining hours
- importance

## Budget / Finance

- weekly budget
- expenses
- remaining budget or sufficient information to calculate it
- spending today
- days remaining where required

## Available Time

- available hours today

## Goals

Only implement if required by the current contract or demo.

Do not over-model the system.

Do not create unnecessary node types or relationships merely to make the
graph look complex.

---

# Jac-Native Persistence

Prefer Jac-native persistence.

Use meaningful Jac graph/state concepts where they serve the product.

Persistent student state should be attached/reachable through the
appropriate Jac persistent root according to the current Jac version.

Do not introduce:

- Supabase
- Firebase
- PostgreSQL
- FastAPI
- custom JSON-file persistence
- a separate Python backend

unless the team explicitly agrees that the current Jac environment
cannot satisfy a required feature.

Do not write raw SQL unless the current Jac implementation specifically
requires it.

---

# Required State Operations

Member 1 should expose the smallest useful state API needed by the demo.

Conceptually:

- initialize or seed demo state
- retrieve StudentSnapshot
- update academic task progress
- add an expense
- update available time

Additional operations should only be added when actually required.

Do not build generic CRUD infrastructure for every possible future
Lifora feature.

---

# Seed State

Use docs/DEMO.md as the source of truth.

The initial demo should represent approximately:

Academic:

- ML Assignment
- due tomorrow
- 40% complete
- approximately 3 hours remaining

- DSA Quiz
- two days away
- low preparation

Finance:

- weekly budget: Rs. 7,000
- remaining: Rs. 3,500
- spent today: Rs. 1,500

Available time:

- 5 hours tonight

Seed logic must NOT continuously overwrite user-modified state.

If existing persistent demo state is present, preserve it unless the
operation explicitly requests a reset.

---

# StudentSnapshot Contract

Follow docs/CONTRACTS.md.

Conceptually:

StudentSnapshot

profile:
- name
- life_stage

academic_tasks:
- id
- title
- deadline
- progress
- estimated_remaining_hours
- importance

finance:
- weekly_budget
- remaining_budget
- spent_today
- days_remaining

available_time:
- available_hours_today

goals:
- list

Do not silently change these fields.

If a contract change becomes genuinely necessary, stop and explain the
required change before modifying the shared interface.

---

# Validation

Use deterministic Jac logic for validation.

Reject or safely handle values such as:

- progress below 0
- progress above 100
- negative expense
- negative available time
- negative estimated remaining work
- empty required task title
- obviously malformed updates

Do not use an LLM for validation.

---

# Planning Service Rules

If editing planning.sv.jac, follow these rules.

planning.sv.jac belongs to Member 2.

Its purpose is conceptually:

StudentSnapshot
    ->
Academic Agent
Finance Agent
Balance Agent
    ->
Coordinator
    ->
CoordinatorResult

Do not put persistent graph implementation into planning.sv.jac.

Do not duplicate specialist-agent logic inside the service.

The service should coordinate/call the intelligence layer and expose the
result through the current Jac server-side mechanism.

---

# Deterministic Logic

Backend deterministic code should handle:

- budget arithmetic
- expense totals
- progress values
- available hours
- validation
- state retrieval
- hard constraints
- simple date/time comparisons where practical

Do not use an LLM for arithmetic.

---

# Testing Member 1 Work

Before reporting state work complete, verify this flow:

1. Application starts.
2. Demo state can be initialized.
3. StudentSnapshot can be retrieved.
4. ML Assignment progress can be changed.
5. Snapshot reflects the new progress.
6. Expense can be added.
7. Snapshot reflects the new finance state.
8. Available time can be changed.
9. Snapshot reflects the new value.
10. State survives normal frontend/backend requests.

Run the current Jac validation command recommended by the root
AGENTS.md.

At minimum, use the appropriate `jac check` command for changed Jac
files.

---

# Scope Restrictions

State work must not implement:

- Academic Agent reasoning
- Finance Agent reasoning
- Balance Agent reasoning
- Coordinator reasoning
- frontend components
- What-If UI
- Career Agent
- Research Agent
- A/L Mode
- Employee Mode

Do not refactor working frontend code.

---

# Git Discipline

Work only on the assigned feature branch.

Member 1 branch:

feature/core-graph

Member 2 planning-service changes:

feature/agents

Before committing:

- inspect git diff
- make sure unrelated files were not changed
- run Jac validation
- never commit secrets
- never commit generated database/runtime state

Prefer small commits with one clear purpose.

---

# Definition of Done

State/backend work is done only when:

- code validates
- application still starts
- required behaviour works
- StudentSnapshot matches the frozen contract
- no unrelated module was modified
- state updates can be demonstrated
- errors are handled without crashing the application

When reporting completion, state:

1. files changed
2. functionality implemented
3. validation commands run
4. tests performed
5. known limitations