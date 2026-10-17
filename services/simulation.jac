"""Non-persistent scenario simulation for the What-If experience."""

import from agents.types { PlanningResponse }
import from services.planning { plan_student }
import from services.snapshot { StudentSnapshot, get_student_snapshot }
import from services.state {
    AcademicTaskView,
    AvailableTimeView,
    FinanceView,
    ProfileView
}

obj SimulationResult {
    has snapshot: StudentSnapshot;
    has plan: PlanningResponse;
}

def copy_snapshot(snapshot: StudentSnapshot) -> StudentSnapshot {
    return StudentSnapshot(
        profile=ProfileView(name=snapshot.profile.name, life_stage=snapshot.profile.life_stage),
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
        goals=[goal for goal in snapshot.goals]
    );
}

def build_simulated_snapshot(snapshot: StudentSnapshot, scenario: str) -> StudentSnapshot {
    simulated = copy_snapshot(snapshot);
    if scenario == "less_time" {
        simulated.available_time.available_hours_today = max(
            0.0, simulated.available_time.available_hours_today - 2.0
        );
    } elif scenario == "spend" {
        simulated.finance.remaining_budget = max(
            0.0, simulated.finance.remaining_budget - 2000.0
        );
        simulated.finance.spent_today += 2000.0;
    } elif scenario == "finish_ml" {
        found = False;
        for task in simulated.academic_tasks {
            if task.id == "ml-assignment" {
                task.progress = 100.0;
                task.estimated_remaining_hours = 0.0;
                found = True;
            }
        }
        if not found {
            raise ValueError("The ML assignment is not available to simulate.");
        }
    } else {
        raise ValueError(f"Unknown simulation scenario '{scenario}'.");
    }
    return simulated;
}

async def:pub simulate_plan(scenario: str) -> SimulationResult {
    current = get_student_snapshot();
    simulated = build_simulated_snapshot(current, scenario);
    plan = await plan_student(simulated);
    return SimulationResult(snapshot=simulated, plan=plan);
}
