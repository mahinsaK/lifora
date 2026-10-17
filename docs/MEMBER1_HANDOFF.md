# Member 1 State Handoff

## Status

The persistent student-state layer is complete through Phase 6. It uses Jac
nodes and typed edges backed by the local Jac PostgreSQL runtime. No raw SQL or
replacement Python service is used.

Implemented modules:

- `services/state.jac` — persistent model, validation, idempotent demo seed,
  and available-time updates
- `services/tasks.jac` — academic-task reads and progress mutations
- `services/finance.jac` — finance reads and expense mutations
- `services/snapshot.jac` — stable `StudentSnapshot` composition

## StudentSnapshot contract

`services.snapshot.StudentSnapshot` exposes exactly these top-level fields:

```text
profile:
  name: string
  life_stage: string

academic_tasks: list of
  id: string
  title: string
  deadline: ISO date string (YYYY-MM-DD)
  progress: number (0-100 percent)
  estimated_remaining_hours: number
  importance: integer (1-5)

finance:
  weekly_budget: number
  remaining_budget: number
  spent_today: number
  days_remaining: integer

available_time:
  available_hours_today: number

goals: list[string]
```

Use `build_student_snapshot(student_id)` from Jac code. The demo-facing public
function is `get_student_snapshot()` and uses the stable demo student ID.

## Available operations

When `services/snapshot.jac` is loaded as the server module, these public Jac
functions are available as `POST /function/<name>` endpoints:

- `initialize_demo_state()`
- `get_student_state()`
- `get_academic_tasks()`
- `update_task_progress(task_id, progress)`
- `get_finance()`
- `add_expense(expense_id, amount, description, spent_on="")`
- `update_available_time(available_hours_today)`
- `get_student_snapshot()`

Expense IDs are idempotency keys. Reusing an ID is rejected before the budget
is changed. An omitted `spent_on` records the expense today; an explicit date
must use `YYYY-MM-DD`.

## Demo seed

Initialization is idempotent and preserves subsequent user mutations.

- Profile: Demo Student, university
- ML Assignment: due tomorrow, 40%, 3 hours remaining, importance 5
- DSA Quiz: due in two days, 20%, 2 hours remaining, importance 4
- Weekly budget: Rs. 7,000
- Remaining budget: Rs. 3,500
- Spent today: Rs. 1,500
- Days remaining: 4
- Available time: 5 hours
- Goals: empty list for the MVP

The DSA numeric values and four budget days are documented implementation
assumptions because the demo specification only says "low preparation" and
does not provide the days remaining.

## Verified mutation flow

The independent test flow verifies:

1. Initialize twice without duplicate students, tasks, budgets, or expenses.
2. Change ML progress from 40% to 90%.
3. Add a unique Rs. 1,000 expense.
4. Observe remaining budget change from Rs. 3,500 to Rs. 2,500.
5. Observe today's spending change from Rs. 1,500 to Rs. 2,500.
6. Read repeatedly without another deduction.
7. Change available time from 5 hours to 2 hours.
8. Read one snapshot containing all updated values.
9. Restart the server and read the same persisted values.

Invalid progress, available hours, expenses, dates, identifiers, and incomplete
state are rejected with explicit errors.

## Validation commands

From the project root:

```bash
jac db status
jac test
jac check .
```

Phase 6 results on Jac 0.37.25:

- 4 test files discovered
- 37/37 repository-wide test executions passed
- 10/10 Jac files passed static validation
- PostgreSQL 18 running with database `jac_empty_dd90f97e`

The static checker still prints existing frontend JSX and untyped-props
warnings. They are outside the Member 1 service scope and do not fail the
check.

## Integration boundary

`main.jac` has intentionally not been changed because it is a shared
integration file requiring approval. The default deployed application must
load `services/snapshot.jac` (directly or through the agreed application
composition) before these public endpoints are exposed. That wiring belongs
to Phase 7 integration support.
