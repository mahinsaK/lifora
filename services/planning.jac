import from datetime { datetime }
import from agents.pipeline { run_pipeline, run_pipeline_at }
import from agents.academic_agent { generate_academic_narrative }
import from agents.balance_agent { generate_balance_narrative }
import from agents.coordinator { generate_coordinator_narrative }
import from agents.finance_agent { generate_finance_narrative }
import from agents.types {
    AcademicAssessment,
    BalanceAssessment,
    CoordinatorNarrative,
    CoordinatorPreparation,
    FinanceAssessment,
    PlanningResponse,
    SpecialistNarrative
}
import from services.snapshot { StudentSnapshot, build_student_snapshot }
import from services.state {
    AcademicTaskView,
    AvailableTimeView,
    DEMO_STUDENT_ID,
    FinanceView,
    ProfileView
}


glob WHAT_IF_LESS_TIME: str = "less_time";
glob WHAT_IF_SPEND: str = "spend";
glob WHAT_IF_FINISH_ML: str = "finish_ml";


obj WhatIfResponse {
    has scenario: str,
        snapshot: StudentSnapshot,
        planning: PlanningResponse;
}


def clone_student_snapshot(snapshot: StudentSnapshot) -> StudentSnapshot {
    return StudentSnapshot(
        profile=ProfileView(
            name=snapshot.profile.name, life_stage=snapshot.profile.life_stage
        ),
        academic_tasks=[
            AcademicTaskView(
                id=task.id,
                title=task.title,
                deadline=task.deadline,
                progress=task.progress,
                estimated_remaining_hours=task.estimated_remaining_hours,
                importance=task.importance
            ) for task in snapshot.academic_tasks
        ],
        finance=FinanceView(
            weekly_budget=snapshot.finance.weekly_budget,
            remaining_budget=snapshot.finance.remaining_budget,
            spent_today=snapshot.finance.spent_today,
            days_remaining=snapshot.finance.days_remaining
        ),
        available_time=AvailableTimeView(
            available_hours_today=snapshot.available_time.available_hours_today
        ),
        goals=snapshot.goals.copy()
    );
}


def build_simulated_snapshot(
    snapshot: StudentSnapshot, scenario: str
) -> StudentSnapshot {
    simulated = clone_student_snapshot(snapshot);
    if scenario == WHAT_IF_LESS_TIME {
        simulated.available_time.available_hours_today = max(
            0.0, simulated.available_time.available_hours_today - 2.0
        );
    } elif scenario == WHAT_IF_SPEND {
        simulated.finance.remaining_budget -= 2000.0;
        simulated.finance.spent_today += 2000.0;
    } elif scenario == WHAT_IF_FINISH_ML {
        found = False;
        for task in simulated.academic_tasks {
            if task.id == "ml-assignment" {
                task.progress = 100.0;
                task.estimated_remaining_hours = 0.0;
                found = True;
            }
        }
        if not found {
            raise ValueError("The ML assignment is unavailable for this scenario.");
        }
    } else {
        raise ValueError(f"Unknown What-If scenario '{scenario}'.");
    }
    return simulated;
}


async def simulate_plan_at(
    snapshot: StudentSnapshot,
    scenario: str,
    current_time: str,
    academic_narrative_generator:
        Callable[
            [AcademicAssessment],
            SpecialistNarrative
        ] = generate_academic_narrative,
    finance_narrative_generator:
        Callable[[FinanceAssessment], SpecialistNarrative] = generate_finance_narrative,
    balance_narrative_generator:
        Callable[[BalanceAssessment], SpecialistNarrative] = generate_balance_narrative,
    coordinator_narrative_generator:
        Callable[
            [CoordinatorPreparation],
            CoordinatorNarrative
        ] = generate_coordinator_narrative
) -> WhatIfResponse {
    simulated = build_simulated_snapshot(snapshot, scenario);
    planning = await run_pipeline_at(
        simulated,
        current_time,
        academic_narrative_generator,
        finance_narrative_generator,
        balance_narrative_generator,
        coordinator_narrative_generator
    );
    return WhatIfResponse(scenario=scenario, snapshot=simulated, planning=planning);
}

async def:pub plan_student(snapshot: StudentSnapshot) -> PlanningResponse {
    return await run_pipeline(snapshot);
}


async def:pub simulate_plan(scenario: str) -> WhatIfResponse {
    snapshot = build_student_snapshot(DEMO_STUDENT_ID);
    return await simulate_plan_at(
        snapshot, scenario, datetime.now().astimezone().isoformat()
    );
}
