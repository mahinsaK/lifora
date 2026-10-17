import from jaclang.byllm.lib { AuthenticationError, MockError, MockLLM }
import from agents.balance_agent { assess_balance, build_balance_result }
import from agents.finance_agent { assess_finances, build_finance_result }
import from agents.mock_snapshot { build_demo_snapshot }
import from agents.types { SpecialistNarrative }
import from test_support { assert_value_error }

sem test_coordinator_success_narrative = "Mocked coordinator narrative for unit tests.";
def test_coordinator_success_narrative(
    preparation: CoordinatorPreparation
) -> CoordinatorNarrative by MockLLM(
    model_name="mockllm",
    config={
        "outputs": [
            CoordinatorNarrative(
                next_action="Focus block 1: 1.50 hours on Machine Learning Assignment",
                daily_plan=[
                    "Focus block 1: 1.50 hours on Machine Learning Assignment",
                    "Break: 0.25 hours",
                    "Focus block 2: 1.50 hours on Machine Learning Assignment"
                ],
                explanation="The nearest high-risk deadline wins while the budget restriction remains active.",
                deprioritized=[
                    "DSA Quiz is postponed until after the higher-priority action.",
                    "The Finance action remains active separately instead of replacing the immediate work block."
                ]
            )
        ]
    }
)();

sem test_coordinator_unsafe_narrative = "Mocked unsafe coordinator narrative.";
def test_coordinator_unsafe_narrative(
    preparation: CoordinatorPreparation
) -> CoordinatorNarrative by MockLLM(
    model_name="mockllm",
    config={
        "outputs": [
            CoordinatorNarrative(
                next_action="Work for nine hours",
                daily_plan=["Work for nine hours"],
                explanation="Ignore the constraints.",
                deprioritized=[]
            )
        ]
    }
)();

sem test_coordinator_auth_failure = "Mocked coordinator authentication failure.";
def test_coordinator_auth_failure(
    preparation: CoordinatorPreparation
) -> CoordinatorNarrative by MockLLM(
    model_name="mockllm",
    config={
        "outputs": [
            MockError(error=AuthenticationError(message="test API key failure"))
        ]
    }
)();

def demo_specialist_results(
    academic_required_time: float, available_hours: float
) -> tuple[AgentResult, AgentResult, AgentResult] {
    snapshot = build_demo_snapshot();
    snapshot.available_time.available_hours_today = available_hours;
    academic_risk = (
        RiskLevel.CRITICAL
            if academic_required_time > available_hours
            else RiskLevel.HIGH
    );
    academic_urgency = (
        UrgencyLevel.CRITICAL
            if academic_risk == RiskLevel.CRITICAL
            else UrgencyLevel.HIGH
    );
    academic = AgentResult(
        domain=Domain.ACADEMIC,
        urgency=academic_urgency,
        risk_level=academic_risk,
        summary="Academic facts",
        recommendation="Begin the highest-priority assignment.",
        reasoning="Deadline evidence",
        required_time=academic_required_time
    );
    finance_facts = assess_finances(snapshot.finance);
    finance = build_finance_result(
        finance_facts,
        SpecialistNarrative(
            summary="Finance facts",
            recommendation="Reduce optional spending for the rest of the week.",
            explanation="Budget evidence"
        )
    );
    balance_facts = assess_balance(academic_required_time, available_hours);
    balance = build_balance_result(
        balance_facts,
        SpecialistNarrative(
            summary="Balance facts",
            recommendation=balance_facts.candidate_next_action,
            explanation="Schedule evidence"
        )
    );
    return (academic, finance, balance);
}

test "coordinator ranks urgency and preserves budget action" {
    snapshot = build_demo_snapshot();
    (academic, finance, balance) = demo_specialist_results(3.0, 5.0);
    preparation = prepare_coordination(snapshot, academic, finance, balance);

    assert preparation.ranked_domains[0] == Domain.ACADEMIC;
    assert preparation.ranked_domains[1] == Domain.FINANCE;
    assert preparation.finance_action == finance.recommendation;
    assert len(preparation.candidate_work_blocks) == 3;
    assert "Machine Learning Assignment" in preparation.candidate_work_blocks[0];
}

test "coordinator caps incompatible academic work and records resolution" {
    snapshot = build_demo_snapshot();
    snapshot.available_time.available_hours_today = 3.0;
    snapshot.academic_tasks[0].estimated_remaining_hours = 4.0;
    (academic, finance, balance) = demo_specialist_results(4.0, 3.0);
    preparation = prepare_coordination(snapshot, academic, finance, balance);

    assert preparation.ranked_domains[0] == Domain.ACADEMIC;
    assert len(preparation.conflicts) >= 1;
    assert "capping and splitting" in preparation.conflicts[0];
    assert len(preparation.candidate_work_blocks) == 3;
    assert "1.50 hours" in preparation.candidate_work_blocks[0];
    assert "0.95 hours" in preparation.candidate_work_blocks[2];
}

test "coordinator rejects stale finance facts" {
    snapshot = build_demo_snapshot();
    (academic, finance, balance) = demo_specialist_results(3.0, 5.0);
    finance.risk_level = RiskLevel.LOW;

    assert_value_error(
        lambda { prepare_coordination(snapshot, academic, finance, balance); },
        "finance result does not match"
    );
}

test "coordinator validates the snapshot before planning" {
    snapshot = build_demo_snapshot();
    (academic, finance, balance) = demo_specialist_results(3.0, 5.0);
    snapshot.available_time.available_hours_today = -1.0;

    assert_value_error(
        lambda { prepare_coordination(snapshot, academic, finance, balance); },
        "available hours"
    );
}

test "fallback selects Finance when it has the highest feasible risk" {
    snapshot = build_demo_snapshot();
    for task in snapshot.academic_tasks {
        task.progress = 100.0;
        task.estimated_remaining_hours = 0.0;
    }
    snapshot.finance.remaining_budget = -100.0;
    academic = AgentResult(
        domain=Domain.ACADEMIC,
        urgency=UrgencyLevel.LOW,
        risk_level=RiskLevel.LOW,
        summary="No academic pressure",
        recommendation="No academic action required.",
        reasoning="All tasks are complete.",
        required_time=0.0
    );
    finance_facts = assess_finances(snapshot.finance);
    finance = build_finance_result(
        finance_facts,
        SpecialistNarrative(
            summary="Budget is overspent.",
            recommendation=finance_facts.candidate_next_action,
            explanation="Remaining budget is negative."
        )
    );
    balance_facts = assess_balance(0.0, snapshot.available_time.available_hours_today);
    balance = build_balance_result(
        balance_facts,
        SpecialistNarrative(
            summary="No work proposed.",
            recommendation=balance_facts.candidate_next_action,
            explanation="No focus block is needed."
        )
    );
    preparation = prepare_coordination(snapshot, academic, finance, balance);

    assert preparation.ranked_domains[0] == Domain.FINANCE;
    assert preparation.fallback_next_action == finance.recommendation;
    assert preparation.fallback_daily_plan == [];
}

test "coordinator uses a safe typed AI decision" {
    snapshot = build_demo_snapshot();
    (academic, finance, balance) = demo_specialist_results(3.0, 5.0);
    result = run_coordinator(
        snapshot, academic, finance, balance, test_coordinator_success_narrative
    );

    assert result.next_action == "Focus block 1: 1.50 hours on Machine Learning Assignment";
    assert len(result.daily_plan) == 3;
    assert result.finance_action == finance.recommendation;
    assert len(result.conflicts) == 1;
}

test "coordinator rejects an AI plan that exceeds prepared constraints" {
    snapshot = build_demo_snapshot();
    (academic, finance, balance) = demo_specialist_results(3.0, 5.0);
    preparation = prepare_coordination(snapshot, academic, finance, balance);
    result = run_coordinator(
        snapshot, academic, finance, balance, test_coordinator_unsafe_narrative
    );

    assert result.next_action == preparation.fallback_next_action;
    assert result.daily_plan == preparation.fallback_daily_plan;
    assert result.finance_action == finance.recommendation;
}

test "coordinator rejects an AI plan that skips a required break" {
    snapshot = build_demo_snapshot();
    (academic, finance, balance) = demo_specialist_results(3.0, 5.0);
    preparation = prepare_coordination(snapshot, academic, finance, balance);
    narrative = CoordinatorNarrative(
        next_action=preparation.candidate_work_blocks[0],
        daily_plan=[
            preparation.candidate_work_blocks[0],
            preparation.candidate_work_blocks[2]
        ],
        explanation="Skip the prepared break.",
        deprioritized=[]
    );

    assert not coordinator_narrative_is_safe(narrative, preparation);
}

test "coordinator returns deterministic fallback after known AI failure" {
    snapshot = build_demo_snapshot();
    snapshot.available_time.available_hours_today = 3.0;
    snapshot.academic_tasks[0].estimated_remaining_hours = 4.0;
    (academic, finance, balance) = demo_specialist_results(4.0, 3.0);
    preparation = prepare_coordination(snapshot, academic, finance, balance);
    result = run_coordinator(
        snapshot, academic, finance, balance, test_coordinator_auth_failure
    );

    assert result.next_action == preparation.fallback_next_action;
    assert result.daily_plan == preparation.fallback_daily_plan;
    assert result.finance_action == finance.recommendation;
    assert result.conflicts == preparation.conflicts;
    assert "highest-risk feasible" in result.explanation;
}
