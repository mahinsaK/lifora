# Lifora — AI and Multi-Agent Engineering Instructions

You own Lifora's runtime intelligence layer.

Read the repository root AGENTS.md first.

Then read:

- docs/PRODUCT.md
- docs/ARCHITECTURE.md
- docs/CONTRACTS.md
- docs/DEMO.md

Use the installed Jac version and current Jac guides as authoritative.

Never guess unfamiliar Jac syntax or outdated byLLM patterns.

---

# Primary Goal

Given one StudentSnapshot, produce one explainable CoordinatorResult.

Core flow:

StudentSnapshot
    |
    +--> Academic Agent
    |
    +--> Finance Agent
    |
    +--> Balance Agent
             |
             v
         Coordinator
             |
             v
      CoordinatorResult

---

# Required Runtime Agents

The MVP contains exactly these specialist/coordinator roles:

1. Academic Agent
2. Finance Agent
3. Balance Agent
4. Coordinator Agent

Do NOT create additional domain agents before the MVP is stable.

Smart Task Breakdown is a helper/tool.

Deadline Risk is deterministic support logic.

The What-If Simulator is a stretch workflow.

They do not need to become additional independent agents.

---

# Development Independence

Do not wait for Member 1.

Create a mock StudentSnapshot matching:

- docs/CONTRACTS.md
- docs/DEMO.md

Use that mock state until the real StudentSnapshot is integrated.

Do not build your own competing persistence/state model.

---

# AgentResult Contract

All specialist agents should produce a structured result matching the
shared contract.

Conceptually:

AgentResult:

- domain
- urgency
- risk_level
- summary
- recommendation
- reasoning
- required_time

Do not silently rename or remove contract fields.

Prefer typed outputs.

Avoid free-form LLM output that later requires fragile parsing.

---

# CoordinatorResult Contract

The Coordinator returns:

- next_action
- daily_plan
- finance_action
- explanation
- conflicts
- deprioritized

This object is the primary intelligence boundary consumed by the
frontend.

Keep it stable.

---

# Deterministic Logic vs AI

Use deterministic Jac code for:

- arithmetic
- urgency inputs that are directly calculable
- budget totals
- remaining budget
- progress percentages
- deadline comparisons
- available-time calculations
- validation
- hard constraints
- risk thresholds where practical
- sorting/ranking before semantic reasoning where appropriate

Use AI/byLLM for:

- contextual interpretation
- comparing competing priorities
- semantic recommendations
- resolving soft conflicts
- generating explanations
- explaining why alternatives were deprioritized
- optional natural-language task breakdown

Never ask an LLM to perform basic arithmetic that Jac can perform
reliably.

---

# Academic Agent

The Academic Agent evaluates academic pressure.

Inputs may include:

- task deadline
- progress
- estimated remaining hours
- importance
- available time
- other academic tasks

It should return:

- urgency
- risk level
- summary
- recommended next academic action
- reasoning
- required time when useful

Example:

ML Assignment:
- due tomorrow
- progress 40%
- approximately 3 hours remaining

Possible outcome:

- high urgency
- recommend beginning/continuing the ML Assignment now

Do not hard-code the final demo answer if the same agent can derive it
from state.

---

# Deadline Risk

Deadline Risk is a core feature.

It should be primarily deterministic.

Recommended levels:

LOW
MEDIUM
HIGH
CRITICAL

Inputs can include:

- remaining work
- available time before deadline
- current progress
- task importance
- time until deadline

Example concept:

required_remaining_time > realistically_available_time
    -> HIGH or CRITICAL

Do not invent false mathematical precision.

The UI needs a clear risk level, not an unsupported probability.

---

# Finance Agent

The Finance Agent handles personal budgeting only.

Evaluate:

- weekly budget
- remaining budget
- recent expenses
- spending today
- days remaining
- spending pressure

Use deterministic arithmetic for totals and remaining values.

Use AI for contextual recommendation/explanation only.

Allowed recommendation style:

- reduce optional spending
- delay a non-essential purchase
- preserve enough money for remaining days

Do NOT provide:

- investment recommendations
- trading advice
- gambling advice
- speculative financial advice
- credit/loan recommendations

---

# Balance Agent

The Balance Agent evaluates schedule feasibility and workload.

Evaluate:

- available time
- academic workload
- amount of focused work proposed
- realistic work blocks
- time conflicts
- buffer/break needs

Its purpose is not merely to say "take a break."

It should create useful constraint information for the Coordinator.

Example:

Academic Agent:
"Use four hours for the ML assignment."

Balance Agent:
"Four uninterrupted hours is unrealistic; split the work into two
focused blocks."

Do not make medical or mental-health diagnoses.

---

# Coordinator Agent

The Coordinator is Lifora's main agentic component.

It receives specialist AgentResults.

It must:

1. compare urgency
2. compare consequences
3. detect conflicting recommendations
4. resolve conflicts
5. choose Best Next Action
6. create a practical Daily Plan
7. explain why the selected action won
8. explain why important alternatives were deprioritized

Do NOT simply concatenate specialist outputs.

---

# Conflict Resolution

Conflict resolution must be visible.

Example:

Academic Agent:
- wants 4 hours on assignment

Balance Agent:
- says only 3 focused hours are realistic

Finance Agent:
- recommends reducing optional spending

Coordinator:

- chooses ML Assignment as immediate priority
- converts 4-hour continuous work into realistic work blocks
- schedules Finance action for later/tomorrow

This is stronger than choosing whichever numeric urgency is highest.

---

# Decision Trace

Decision Trace is mandatory.

CoordinatorResult should provide enough structured information for the
frontend to show:

Academic Agent:
- urgency
- recommendation
- reason

Finance Agent:
- urgency
- recommendation
- reason

Balance Agent:
- urgency
- recommendation
- reason

Coordinator:
- detected conflict
- selected action
- why it won
- how conflict was resolved
- what was deprioritized
- why it was deprioritized

Do not hide all reasoning inside one paragraph.

Prefer structured fields that are easy for Member 3 to render.

---

# Daily Plan

The Coordinator should produce a practical ordered plan.

Example style:

- 6:00–7:30 ML Assignment
- short break
- 7:50–9:20 ML Assignment
- 9:20–10:00 DSA Review

Do not over-engineer scheduling.

The hackathon needs a clear practical result, not a full calendar
optimization engine.

---

# Graceful AI Failure

Every AI call must fail safely.

If byLLM fails:

- do not crash the app
- preserve real user state
- do not invent missing data
- return a safe structured fallback where possible
- communicate that AI reasoning was unavailable

Where reasonable, deterministic deadline/budget calculations should
still function without the LLM.

---

# Smart Task Breakdown

Priority: P2

Implement only after:

- Academic Agent works
- Finance Agent works
- Balance Agent works
- Coordinator works
- Decision Trace works

Task Breakdown should be a helper used by the Academic Agent or planning
workflow.

It may transform a natural-language task into practical subtasks.

Example:

ML Assignment
    ->
Review requirements
Prepare data
Implement/train
Evaluate
Write analysis
Final review

Do not create a fifth domain agent merely for task breakdown.

---

# What-If Simulator

Priority: P3 / stretch only.

Do not implement until the core MVP is stable.

Required architecture:

Real StudentSnapshot
    ->
clone
    ->
apply temporary scenario override
    ->
SimulatedSnapshot
    ->
run SAME Academic Agent
run SAME Finance Agent
run SAME Balance Agent
    ->
run SAME Coordinator
    ->
compare real result vs simulated result

Never mutate persistent real state.

Recommended demo scenarios:

1. available time decreases by 2 hours
2. unexpected Rs. 2,000 expense
3. ML Assignment becomes 100% complete

Do not build a second separate intelligence architecture for
simulation.

---

# Required Test Scenarios

Test at minimum:

## Scenario 1 — Initial demo

- ML Assignment 40%
- due tomorrow
- DSA Quiz in two days
- Rs. 3,500 remaining
- 5 hours available

## Scenario 2 — Progress increases

Change:

40% -> 90%

Expected:

- Academic urgency should reduce appropriately
- Coordinator may change plan

## Scenario 3 — New expense

Add:

Rs. 1,000

Expected:

- Finance pressure increases
- Finance recommendation reacts

## Scenario 4 — Reduced time

5 hours -> 2 hours

Expected:

- deadline/schedule pressure increases
- Balance Agent reacts
- Coordinator replans

## Scenario 5 — Conflict

Ensure specialist agents produce recommendations that genuinely require
Coordinator resolution.

---

# Scope Restrictions

Do not modify:

- persistent graph design unless required for integration
- frontend components
- styles
- product scope
- shared contracts without team agreement

Do not add:

- Career Agent
- Research Agent
- A/L Mode
- Employee Mode
- live job scraping
- scholarship search
- recommendation marketplaces

---

# Validation

After meaningful changes:

- run the appropriate `jac check`
- run focused agent tests
- verify the mock StudentSnapshot still works
- make sure CoordinatorResult follows docs/CONTRACTS.md
- make sure fallback behaviour does not crash

Before integration, the complete intelligence pipeline must work using
mock data.

---

# Git Discipline

Member 2 branch:

feature/agents

Keep commits focused.

Suggested progression:

1. types + mock snapshot
2. deadline risk
3. Academic Agent
4. Finance Agent
5. Balance Agent
6. Coordinator
7. Decision Trace
8. planning service integration
9. optional task breakdown
10. optional simulator

Do not combine all work into one massive commit.

---

# Definition of Done

Intelligence work is complete when:

- specialist agents work
- Coordinator works
- real conflict resolution occurs
- Decision Trace is structured
- deadline risk works
- mock demo state produces usable results
- CoordinatorResult matches shared contract
- validation passes
- failures are handled gracefully

When reporting completion, state:

1. files changed
2. implemented functionality
3. validation performed
4. test scenarios executed
5. remaining limitations