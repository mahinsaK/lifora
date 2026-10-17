# Lifora Architecture

## Conceptual pipeline

```text
Student Persistent State
        ↓
StudentSnapshot
        ↓
Academic Agent     Finance Agent     Balance Agent
        \                 |                 /
                 Coordinator
                      ↓
              CoordinatorResult
                      ↓
                 Jac frontend
```

The snapshot is the consistent input for one planning pass. Specialist agents assess their own domains; the Coordinator resolves trade-offs and produces one result for the frontend. A state change triggers a fresh snapshot and planning pass.

## Persistent conceptual entities
- `User` / `Profile`
- `AcademicTask`
- `Budget`
- `Expense`
- Available time
- `Goal` if needed

These are conceptual boundaries, not implemented schemas. Model persisted state with Jac-native graph entities and relations when that work begins; do not introduce an external database by default.

## Responsibility boundary

Use deterministic Jac logic for arithmetic, budget calculations, percentages, deadline comparisons, available-time calculations, validation, filtering, and sorting. Use AI / `by llm()` for contextual reasoning, prioritization, resolving soft conflicts, explanations, and optional task breakdown. AI output must not be trusted for exact arithmetic or validation.

## Current implementation

`main.jac` mounts `components/LiforaDashboard.jac`; `styles/global.css` supplies the client theme. There are no server modules or persistence yet. Extend this Jac web app with Jac server functions and graph-backed state as requirements arrive. Keep frontend state updates explicit: reflect mutations in the UI and request a new planning result after relevant state changes. No agents or new product functionality are implemented by this documentation change.
