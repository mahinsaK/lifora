import asyncio;
import from jaclang.byllm.lib { AuthenticationError, MockError, MockLLM }
import from agents.mock_snapshot { build_demo_snapshot }
import from agents.types {
    AcademicAssessment,
    BalanceAssessment,
    CoordinatorNarrative,
    CoordinatorPreparation,
    FinanceAssessment,
    RiskLevel,
    SpecialistNarrative
}
import from test_support { assert_value_error }


glob FIXED_WHAT_IF_NOW = "2026-10-17T18:00:00+05:30";


sem what_if_academic_narrative = "Mocked academic failure for What-If tests.";
def what_if_academic_narrative(assessment: AcademicAssessment) -> SpecialistNarrative by MockLLM(
    model_name="mockllm",
    config={"outputs": [MockError(error=AuthenticationError(message="offline"))]}
)();


sem what_if_finance_narrative = "Mocked finance failure for What-If tests.";
def what_if_finance_narrative(assessment: FinanceAssessment) -> SpecialistNarrative by MockLLM(
    model_name="mockllm",
    config={"outputs": [MockError(error=AuthenticationError(message="offline"))]}
)();


sem what_if_balance_narrative = "Mocked balance failure for What-If tests.";
def what_if_balance_narrative(assessment: BalanceAssessment) -> SpecialistNarrative by MockLLM(
    model_name="mockllm",
    config={"outputs": [MockError(error=AuthenticationError(message="offline"))]}
)();


sem what_if_coordinator_narrative = "Mocked coordinator failure for What-If tests.";
def what_if_coordinator_narrative(
    preparation: CoordinatorPreparation
) -> CoordinatorNarrative by MockLLM(
    model_name="mockllm",
    config={"outputs": [MockError(error=AuthenticationError(message="offline"))]}
)();


def run_what_if(scenario: str) -> WhatIfResponse {
    return asyncio.run(
        simulate_plan_at(
            build_demo_snapshot(),
            scenario,
            FIXED_WHAT_IF_NOW,
            what_if_academic_narrative,
            what_if_finance_narrative,
            what_if_balance_narrative,
            what_if_coordinator_narrative
        )
    );
}


test "less-time simulation is isolated and raises balance pressure" {
    original = build_demo_snapshot();
    response = asyncio.run(
        simulate_plan_at(
            original,
            WHAT_IF_LESS_TIME,
            FIXED_WHAT_IF_NOW,
            what_if_academic_narrative,
            what_if_finance_narrative,
            what_if_balance_narrative,
            what_if_coordinator_narrative
        )
    );

    assert original.available_time.available_hours_today == 5.0;
    assert response.snapshot.available_time.available_hours_today == 3.0;
    assert response.planning.balance.risk_level == RiskLevel.HIGH;
}


test "spending simulation changes only the hypothetical finance facts" {
    original = build_demo_snapshot();
    response = run_what_if(WHAT_IF_SPEND);

    assert original.finance.remaining_budget == 3500.0;
    assert original.finance.spent_today == 1500.0;
    assert response.snapshot.finance.remaining_budget == 1500.0;
    assert response.snapshot.finance.spent_today == 3500.0;
    assert response.planning.finance.risk_level == RiskLevel.CRITICAL;
}


test "finishing ML clears its remaining work and promotes DSA" {
    response = run_what_if(WHAT_IF_FINISH_ML);
    ml_task = response.snapshot.academic_tasks[0];

    assert ml_task.id == "ml-assignment";
    assert ml_task.progress == 100.0;
    assert ml_task.estimated_remaining_hours == 0.0;
    assert response.planning.academic.required_time == 2.0;
    assert "DSA Quiz" in response.planning.academic.recommendation;
}


test "unknown What-If scenarios are rejected" {
    assert_value_error(
        lambda { build_simulated_snapshot(build_demo_snapshot(), "unknown"); },
        "Unknown What-If scenario"
    );
}
