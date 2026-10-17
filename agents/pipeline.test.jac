import asyncio;
import from jaclang.byllm.lib { AuthenticationError, MockError, MockLLM }
import from agents.finance_agent { assess_finances }
import from agents.mock_snapshot { build_demo_snapshot }
import from agents.types {
    AcademicAssessment,
    BalanceAssessment,
    CoordinatorNarrative,
    CoordinatorPreparation,
    FinanceAssessment,
    PlanningResponse,
    RiskLevel,
    SpecialistNarrative,
    StudentSnapshot,
    UrgencyLevel
}

glob llm = MockLLM(outputs=[]),
     FIXED_PIPELINE_NOW = "2026-10-17T18:00:00+05:30";

sem pipeline_academic_narrative = "Mocked academic narrative for pipeline tests.";
def pipeline_academic_narrative(assessment: AcademicAssessment) -> SpecialistNarrative by llm(
    max_output_retries=0
);

sem pipeline_finance_narrative = "Mocked finance narrative for pipeline tests.";
def pipeline_finance_narrative(assessment: FinanceAssessment) -> SpecialistNarrative by llm(
    max_output_retries=0
);

sem pipeline_balance_narrative = "Mocked balance narrative for pipeline tests.";
def pipeline_balance_narrative(assessment: BalanceAssessment) -> SpecialistNarrative by llm(
    max_output_retries=0
);

sem pipeline_coordinator_narrative = "Mocked coordinator narrative for pipeline tests.";
def pipeline_coordinator_narrative(
    preparation: CoordinatorPreparation
) -> CoordinatorNarrative by llm(max_output_retries=0);

def failed_ai_model -> MockLLM {
    return MockLLM(
        outputs=[
            MockError(error=AuthenticationError(message="academic AI unavailable")),
            MockError(error=AuthenticationError(message="finance AI unavailable")),
            MockError(error=AuthenticationError(message="balance AI unavailable")),
            MockError(error=AuthenticationError(message="coordinator AI unavailable"))
        ]
    );
}

def run_with_deterministic_fallback(snapshot: StudentSnapshot) -> PlanningResponse {
    response = asyncio.run(
        run_pipeline_at(
            snapshot,
            FIXED_PIPELINE_NOW,
            pipeline_academic_narrative,
            pipeline_finance_narrative,
            pipeline_balance_narrative,
            pipeline_coordinator_narrative
        )
    );
    assert llm.exhausted();
    return response;
}

test "initial scenario produces a feasible ML assignment plan" {
    llm = failed_ai_model();
    response = run_with_deterministic_fallback(build_demo_snapshot());

    assert response.academic.urgency == UrgencyLevel.HIGH;
    assert response.academic.risk_level == RiskLevel.HIGH;
    assert "ML Assignment" in response.academic.recommendation;
    assert "ML Assignment" in response.coordinator.next_action;
    assert response.balance.risk_level == RiskLevel.LOW;
    assert response.coordinator.daily_plan
        == [
            "Focus block 1: 1.50 hours on ML Assignment",
            "Break: 0.25 hours",
            "Focus block 2: 1.50 hours on ML Assignment"
        ];
}

test "progress increase lowers urgency and triggers replanning" {
    snapshot = build_demo_snapshot();
    llm = failed_ai_model();
    initial = run_with_deterministic_fallback(snapshot);
    snapshot.academic_tasks[0].progress = 90.0;
    llm = failed_ai_model();
    updated = run_with_deterministic_fallback(snapshot);

    assert initial.academic.urgency == UrgencyLevel.HIGH;
    assert updated.academic.urgency == UrgencyLevel.MEDIUM;
    assert updated.academic.risk_level == RiskLevel.MEDIUM;
    assert initial.coordinator.next_action != updated.coordinator.next_action;
    assert updated.coordinator.next_action == updated.finance.recommendation;
    assert "DSA Quiz" in updated.coordinator.deprioritized[0];
}

test "added expense reduces budget and changes finance response" {
    snapshot = build_demo_snapshot();
    initial_facts = assess_finances(snapshot.finance);
    llm = failed_ai_model();
    initial = run_with_deterministic_fallback(snapshot);
    snapshot.finance.remaining_budget -= 1000.0;
    snapshot.finance.spent_today += 1000.0;
    updated_facts = assess_finances(snapshot.finance);
    llm = failed_ai_model();
    updated = run_with_deterministic_fallback(snapshot);

    assert initial_facts.remaining_budget == 3500.0;
    assert updated_facts.remaining_budget == 2500.0;
    assert initial.finance.risk_level == RiskLevel.HIGH;
    assert updated.finance.risk_level == RiskLevel.CRITICAL;
    assert initial.finance.recommendation != updated.finance.recommendation;
    assert "Pause optional spending" in updated.finance.recommendation;
}

test "reduced available time creates a shorter feasible plan" {
    snapshot = build_demo_snapshot();
    llm = failed_ai_model();
    initial = run_with_deterministic_fallback(snapshot);
    snapshot.available_time.available_hours_today = 2.0;
    llm = failed_ai_model();
    updated = run_with_deterministic_fallback(snapshot);

    assert initial.balance.risk_level == RiskLevel.LOW;
    assert updated.balance.risk_level == RiskLevel.CRITICAL;
    assert "defer the remainder" in updated.balance.recommendation;
    assert updated.coordinator.daily_plan != initial.coordinator.daily_plan;
    assert updated.coordinator.daily_plan
        == [
            "Focus block 1: 1.50 hours on ML Assignment",
            "Break: 0.25 hours",
            "Focus block 2: 0.05 hours on ML Assignment"
        ];
}

test "coordinator records and resolves a genuine schedule conflict" {
    snapshot = build_demo_snapshot();
    snapshot.academic_tasks[0].estimated_remaining_hours = 4.0;
    snapshot.available_time.available_hours_today = 3.0;
    llm = failed_ai_model();
    response = run_with_deterministic_fallback(snapshot);

    assert response.academic.required_time == 4.0;
    assert response.balance.required_time < response.academic.required_time;
    assert response.balance.risk_level == RiskLevel.CRITICAL;
    assert len(response.coordinator.conflicts) >= 1;
    assert "capping and splitting" in response.coordinator.conflicts[0];
    assert abs(response.balance.required_time - 2.45) < 0.001;
}

test "known AI failures return a safe deterministic planning response" {
    snapshot = build_demo_snapshot();
    finance_facts = assess_finances(snapshot.finance);
    llm = failed_ai_model();
    response = run_with_deterministic_fallback(snapshot);

    assert response.academic.risk_level == RiskLevel.HIGH;
    assert response.finance.risk_level == finance_facts.budget_pressure;
    assert finance_facts.remaining_budget == 3500.0;
    assert "AI reasoning was unavailable" in response.academic.reasoning;
    assert "AI reasoning was unavailable" in response.finance.reasoning;
    assert "AI reasoning was unavailable" in response.balance.reasoning;
    assert response.coordinator.next_action != "";
    assert len(response.coordinator.daily_plan) > 0;
}
