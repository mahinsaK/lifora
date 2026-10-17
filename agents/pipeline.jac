import from datetime { datetime }
import from agents.academic_agent { generate_academic_narrative, run_academic_agent }
import from agents.balance_agent { generate_balance_narrative, run_balance_agent }
import from agents.coordinator { generate_coordinator_narrative, run_coordinator }
import from agents.finance_agent { generate_finance_narrative, run_finance_agent }
import from agents.types {
    AcademicAssessment,
    BalanceAssessment,
    CoordinatorNarrative,
    CoordinatorPreparation,
    FinanceAssessment,
    PlanningResponse,
    SpecialistNarrative,
    StudentSnapshot
}

async def run_pipeline_at(
    snapshot: StudentSnapshot,
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
) -> PlanningResponse {
    academic = run_academic_agent(
        current_time,
        snapshot.academic_tasks,
        snapshot.available_time.available_hours_today,
        academic_narrative_generator
    );
    finance = run_finance_agent(snapshot.finance, finance_narrative_generator);
    balance = run_balance_agent(
        academic.required_time,
        snapshot.available_time.available_hours_today,
        balance_narrative_generator
    );
    coordinator = run_coordinator(
        snapshot, academic, finance, balance, coordinator_narrative_generator
    );

    return PlanningResponse(
        academic=academic, finance=finance, balance=balance, coordinator=coordinator
    );
}

async def run_pipeline(snapshot: StudentSnapshot) -> PlanningResponse {
    current_time = datetime.now().astimezone().isoformat();
    return await run_pipeline_at(snapshot, current_time);
}
