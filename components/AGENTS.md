# Lifora — Frontend, UX and Demo Engineering Instructions

You own Lifora's user-facing experience.

Read the repository root AGENTS.md first.

Then read:

- docs/PRODUCT.md
- docs/ARCHITECTURE.md
- docs/CONTRACTS.md
- docs/DEMO.md

The JacHammer project already contains a working LiforaDashboard.

Extend the existing application.

Do NOT rebuild the frontend architecture from scratch unless the current
implementation is genuinely unusable.

---

# Primary Goal

A judge should understand Lifora quickly.

Within approximately 20 seconds, the UI should communicate:

1. who the user is
2. current academic state
3. current financial state
4. available time
5. what Lifora recommends next
6. why Lifora made that decision

Prioritize clarity and demo reliability over visual complexity.

---

# Development Independence

Do not wait for Member 1 or Member 2.

Use mock data matching:

- StudentSnapshot
- AgentResult
- CoordinatorResult

from docs/CONTRACTS.md.

Develop the complete UI against mocks first.

During integration, replace mocks with real backend/service calls.

Do not redesign the interface during integration.

---

# Core Dashboard

The main Lifora dashboard should display:

- Lifora branding
- University Mode
- tagline
- Academic status
- Finance status
- Available Time / Balance status
- "What Should I Do Next?" primary action
- Best Next Action
- Daily Plan
- Deadline Risk
- Decision Trace

Avoid unnecessary navigation/pages.

The hackathon demo should ideally be understandable from one main
workflow.

---

# Branding

Product name:

Lifora

Primary tagline:

"One life. Many priorities. One intelligent next step."

Optional supporting line:

"Understand today. Simulate tomorrow. Decide better."

Do not let branding take time away from functionality.

---

# Academic UI

Show enough information to understand academic pressure.

Useful fields:

- task title
- deadline
- progress
- estimated remaining work
- risk level

Example:

ML Assignment
40% complete
Due tomorrow
3h remaining
Risk: HIGH

Do not clutter the card with backend-only data.

---

# Finance UI

Show:

- weekly budget
- remaining budget
- recent/today spending
- Finance Agent recommendation when results exist

Keep financial information simple.

Do not add advanced charts unless they clearly improve the demo.

---

# Available Time / Balance UI

Show:

- available hours today
- workload/schedule status
- Balance Agent recommendation when available

Keep the card immediately understandable.

---

# Main Action

The primary user action is:

"What Should I Do Next?"

When triggered, the UI should eventually:

1. obtain current student state
2. run/request Lifora planning
3. show specialist analysis
4. show Coordinator result
5. show Best Next Action
6. show Daily Plan
7. show Decision Trace

Use loading/error states where appropriate.

Do not leave the interface frozen if AI takes time.

---

# Best Next Action

This is the visual centerpiece of the result.

Make the selected action obvious.

Example:

BEST NEXT ACTION

Continue the ML Assignment now.

Reason:
It has the nearest deadline and highest immediate academic risk.

Do not bury the decision inside a long paragraph.

---

# Daily Plan

Display the Coordinator's ordered plan clearly.

Example:

6:00–7:30
ML Assignment

7:30–7:50
Break

7:50–9:20
ML Assignment

9:20–10:00
DSA Review

Use the data returned by CoordinatorResult.

Do not invent conflicting frontend-only scheduling logic.

---

# Deadline Risk UI

Deadline Risk is a core feature.

Use understandable labels:

LOW
MEDIUM
HIGH
CRITICAL

The risk should be visually noticeable.

Do not manufacture fake probability percentages.

The source of truth is Member 2's deadline-risk result.

---

# Decision Trace UI

Decision Trace is mandatory.

It must visibly prove that multiple agents contributed to the final
decision.

Show something structurally like:

Academic Agent
- urgency
- recommendation
- reason

Finance Agent
- urgency
- recommendation
- reason

Balance Agent
- urgency
- recommendation
- reason

Then:

Coordinator
- conflict detected
- selected action
- why it won
- how conflict was resolved
- alternatives deprioritized
- why they were deprioritized

The judge should not need to inspect source code to understand that
multi-agent coordination occurred.

---

# Dynamic Replanning Controls

The demo must support changing real state and re-running Lifora.

Required controls:

## Update Assignment Progress

Demo:

40% -> 90%

## Add Expense

Demo:

+ Rs. 1,000

Optional if easy:

## Update Available Time

Demo:

5h -> 2h

After a state mutation, allow the user to run Lifora again and visibly
show changed recommendations.

Do not simulate these changes only in frontend state after real backend
integration is available.

---

# Mock-First Values

Before real integration, use the demo state from docs/DEMO.md.

Academic:

- ML Assignment
- due tomorrow
- 40% progress
- approximately 3 hours remaining

- DSA Quiz
- two days away
- low preparation

Finance:

- weekly budget Rs. 7,000
- remaining Rs. 3,500
- spent today Rs. 1,500

Available Time:

- 5 hours

Mock CoordinatorResult should demonstrate:

- Best Next Action
- Daily Plan
- explanation
- conflict
- deprioritized alternatives

Mocks must follow the real shared contracts so integration requires as
few UI changes as possible.

---

# Error Handling

Frontend must remain usable if:

- backend state request fails
- planning/AI request fails
- one response is missing
- network request takes time

Show a simple understandable message.

Do not expose raw stack traces or implementation errors in the main UI.

Do not erase existing visible state simply because AI reasoning failed.

---

# What-If UI

Priority: stretch only.

Do NOT start before:

- real state works
- real planning works
- Decision Trace works
- dynamic replanning works

Keep the UI tiny.

Recommended predefined buttons:

- I have 2 fewer hours tonight
- I unexpectedly spend Rs. 2,000
- I finish the ML assignment early

Display comparison:

CURRENT
vs
WHAT-IF

Useful comparison fields:

- changed state
- Academic urgency
- Finance urgency
- Balance urgency
- Best Next Action
- explanation

Do not create a large custom scenario editor.

Never persist the simulated scenario as real user state.

---

# Scope Restrictions

Do not implement:

- backend persistence
- Academic Agent logic
- Finance Agent logic
- Balance Agent logic
- Coordinator logic
- authentication unless absolutely necessary
- notifications
- social features
- career mode
- A/L mode
- employee mode
- job search
- scholarships
- transport
- payment

Do not convert the application to React/Next/Vue merely because those
frameworks are familiar.

Use the current Jac client architecture.

---

# Submission Responsibilities

Member 3 also owns the presentation layer of the submission.

Maintain:

- README
- useful screenshots
- project description
- demo script
- demo video
- pitch deck

The README should clearly explain:

1. problem
2. Lifora solution
3. University Student Mode
4. Jac architecture
5. persistent state
6. specialist agents
7. Coordinator
8. Decision Trace
9. dynamic replanning
10. What-If Simulator if implemented
11. how to run the app
12. demo scenario

Do not spend significant time polishing README before the application
works.

---

# Demo-Critical Path

Never break this sequence:

1. Open Lifora
2. Show initial student state
3. Click "What Should I Do Next?"
4. Show specialist results
5. Show Best Next Action
6. Show Daily Plan
7. Show Decision Trace
8. Change ML Assignment from 40% to 90%
9. Run again
10. Show recommendation changing
11. Add Rs. 1,000 expense
12. Run again
13. Show Finance Agent reacting

If What-If exists:

14. choose one scenario
15. show Current vs What-If
16. show recommendation difference

---

# Validation

Before reporting frontend work complete:

- run current Jac validation
- load the dashboard
- test mock state
- test mock result state
- test loading state
- test error state
- verify the main action
- verify Decision Trace
- verify dynamic state controls

After real integration:

- verify state data is from backend
- verify planning result is real
- verify forms mutate real state
- verify rerun changes results

---

# Git Discipline

Member 3 branch:

feature/frontend

Prefer focused commits.

Examples:

- dashboard state cards
- Best Next Action + Daily Plan
- Decision Trace
- state update controls
- backend integration
- demo polish

Do not make unrelated backend changes.

Avoid broad refactors once integration starts.

---

# Definition of Done

Frontend work is complete when:

- dashboard loads
- current state is readable
- main Lifora action works
- Best Next Action is obvious
- Daily Plan renders
- Deadline Risk renders
- Decision Trace clearly demonstrates multi-agent reasoning
- progress update flow works
- expense update flow works
- real integration works
- demo path is reliable

When reporting completion, state:

1. files changed
2. visible functionality implemented
3. validation performed
4. demo flows tested
5. remaining limitations