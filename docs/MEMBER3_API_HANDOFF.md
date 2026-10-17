# Member 3 API Handoff

## Frozen MVP sequence

This is the frontend integration sequence for the Lifora MVP. Keep the endpoint
names, parameter names, and response fields unchanged unless the team agrees to
a contract change.

All operations are public Jac function RPCs. A Jac client component should use
`sv import` and `await` every call. A raw HTTP client should use
`POST /function/<name>` with a JSON body and read the function return value from
`data.result` in the standard Jac response envelope.

## Required client imports

```jac
sv import from services.state { initialize_demo_state }
sv import from services.snapshot { get_student_snapshot }
sv import from services.planning { plan_student }
sv import from services.tasks { update_task_progress }
sv import from services.finance { add_expense }
```

## 1. Initialize demo state

Call once when preparing the demo:

```text
POST /function/initialize_demo_state
{}
```

Equivalent Jac client call:

```jac
_ = await initialize_demo_state();
```

Initialization is idempotent. It creates missing demo state but deliberately
does not reset existing progress, expenses, or available-time changes.

## 2. Load the current snapshot

```text
POST /function/get_student_snapshot
{}
```

```jac
snapshot = await get_student_snapshot();
```

The returned `StudentSnapshot` contains:

- `profile`
- `academic_tasks`
- `finance`
- `available_time`
- `goals`

The current state service emits task deadlines as ISO calendar dates such as
`2026-10-19`. The planning adapter converts them to timezone-aware end-of-day
timestamps before deadline calculations. The frontend should display the date
from the snapshot and must not perform its own risk calculation.

## 3. Run planning

Send the complete snapshot back to the planning endpoint:

```text
POST /function/plan_student
{
  "snapshot": <the complete StudentSnapshot from step 2>
}
```

```jac
planning = await plan_student(snapshot);
```

Do not construct a second snapshot type in the frontend and do not send only
selected fields.

## 4. Render the planning response

`PlanningResponse` contains four separate results:

```text
academic: AgentResult
finance: AgentResult
balance: AgentResult
coordinator: CoordinatorResult
```

Render the specialist results independently:

- `academic.urgency`, `academic.risk_level`, `academic.summary`,
  `academic.recommendation`, `academic.reasoning`, `academic.required_time`
- the same fields from `finance`
- the same fields from `balance`

Use `academic.risk_level` for the MVP Deadline Risk display. Do not calculate a
different risk value in the frontend.

Render the Coordinator fields as follows:

- Best Next Action: `coordinator.next_action`
- Daily Plan: `coordinator.daily_plan`
- Finance action: `coordinator.finance_action`
- Why the action won: `coordinator.explanation`
- Conflicts and resolutions: `coordinator.conflicts`
- Postponed alternatives: `coordinator.deprioritized`

The Decision Trace must show all three specialist results plus the Coordinator
fields. Do not merge the specialist explanations into one paragraph.

## 5. Update ML progress and replan

```text
POST /function/update_task_progress
{
  "task_id": "ml-assignment",
  "progress": 90.0
}
```

```jac
_ = await update_task_progress("ml-assignment", 90.0);
snapshot = await get_student_snapshot();
planning = await plan_student(snapshot);
```

Always fetch a fresh snapshot after the write. Never change only the browser's
copy and reuse the old planning response.

Expected demo behavior:

- ML progress becomes 90 percent.
- Academic urgency decreases from the initial scenario.
- The Coordinator returns a newly calculated action and plan.

## 6. Add the Rs. 1,000 expense and replan

```text
POST /function/add_expense
{
  "expense_id": "demo-extra-1000-01",
  "amount": 1000.0,
  "description": "Demo additional expense"
}
```

The `expense_id` is an idempotency key and must be unique for each persisted
expense. Reusing an existing ID returns an error and does not deduct the amount
again.

```jac
_ = await add_expense(
    "demo-extra-1000-01",
    1000.0,
    "Demo additional expense"
);
snapshot = await get_student_snapshot();
planning = await plan_student(snapshot);
```

Expected demo behavior from a clean initial state:

- Remaining budget changes from Rs. 3,500 to Rs. 2,500.
- Spending today changes from Rs. 1,500 to Rs. 2,500.
- Finance pressure becomes `CRITICAL`.
- The Finance recommendation changes and remains separately visible in the
  Coordinator result.

## Frontend state rules

1. Disable mutation and planning buttons while their request is running.
2. Keep the last successful snapshot and planning result visible on an error.
3. Show a concise error message instead of a raw exception.
4. After every successful mutation, refetch the snapshot and call
   `plan_student` again.
5. Use the returned deterministic urgency, risk, budget, time, conflict, and
   plan values without recalculating them in the frontend.
6. Before recording the official demo, verify that the persisted database is
   at the documented initial state. `initialize_demo_state` does not reset an
   already-mutated demo student.

## Frozen endpoint list

```text
initialize_demo_state() -> StateInitializationResult
get_student_snapshot() -> StudentSnapshot
plan_student(snapshot: StudentSnapshot) -> PlanningResponse
update_task_progress(task_id: str, progress: float) -> AcademicTaskView
add_expense(
    expense_id: str,
    amount: float,
    description: str,
    spent_on: str = ""
) -> ExpenseRecordResult
```
