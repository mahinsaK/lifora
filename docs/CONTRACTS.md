# Lifora Conceptual Contracts

These are planning contracts for future Jac types and endpoints, not implemented runtime schemas. Keep stable identifiers and explicit units; represent progress as a percentage from 0 to 100 and time in hours.

## StudentSnapshot

```text
profile:
  name: string
  life_stage: string

academic_tasks: list of
  id: string
  title: string
  deadline: date/time
  progress: number (0–100 percent)
  estimated_remaining_hours: number
  importance: number

finance:
  weekly_budget: money
  remaining_budget: money
  spent_today: money
  days_remaining: integer

available_time:
  available_hours_today: number

goals: list
```

All monetary values in one snapshot use the same currency. Deadline and duration comparisons use validated, normalized values.

## AgentResult

```text
domain: string
urgency: string
risk_level: string
summary: string
recommendation: string
reasoning: string
required_time: number (hours)
```

`domain` identifies the specialist. Urgency and risk use documented bounded vocabularies when concrete types are introduced. Keep reasoning concise and tied to snapshot evidence.

## CoordinatorResult

```text
next_action: string
daily_plan: list
finance_action: string
explanation: string
conflicts: list
deprioritized: list
```

The Coordinator consumes the snapshot and available specialist results. `next_action` is the primary recommendation; explanation and conflicts make trade-offs inspectable. The plan must respect deterministic time and budget constraints.

## Replanning

A state mutation is validated and persisted before obtaining a fresh snapshot. Re-run affected specialist assessments and coordination; return a new result for the frontend. A what-if run, when added, must use an isolated hypothetical snapshot and never mutate persisted state.
