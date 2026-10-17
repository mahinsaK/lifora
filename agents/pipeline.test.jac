import asyncio;
import from jaclang.byllm.lib { AuthenticationError, MockError, MockLLM }
import from agents.finance_agent { assess_finances }
import from agents.mock_snapshot { build_demo_snapshot }
import from services.snapshot { StudentSnapshot, build_student_snapshot }
import from services.state {
    HasAcademicTask,
    HasBudget,
    HasExpense,
    Student,
    find_student,
    initialize_academic_task,
    initialize_demo_finance,
    initialize_student
}
import from agents.types {
    AcademicAssessment,
    BalanceAssessment,
    CoordinatorNarrative,
    CoordinatorPreparation,
    FinanceAssessment,
    PlanningResponse,
    RiskLevel,
    SpecialistNarrative,
    UrgencyLevel
}

glob FIXED_PIPELINE_NOW = "2026-10-17T18:00:00+05:30";

sem pipeline_academic_narrative = "Mocked academic narrative failure for pipeline tests.";
def pipeline_academic_narrative(assessment: AcademicAssessment) -> SpecialistNarrative by MockLLM(
    model_name="mockllm",
    config={
        "outputs": [
            MockError(error=AuthenticationError(message="academic AI unavailable"))
        ]
    }
)(
    max_output_retries=0
);

sem pipeline_finance_narrative = "Mocked finance narrative failure for pipeline tests.";
def pipeline_finance_narrative(assessment: FinanceAssessment) -> SpecialistNarrative by MockLLM(
    model_name="mockllm",
    config={
        "outputs": [
            MockError(error=AuthenticationError(message="finance AI unavailable"))
        ]
    }
)(
    max_output_retries=0
);

sem pipeline_balance_narrative = "Mocked balance narrative failure for pipeline tests.";
def pipeline_balance_narrative(assessment: BalanceAssessment) -> SpecialistNarrative by MockLLM(
    model_name="mockllm",
    config={
        "outputs": [
            MockError(error=AuthenticationError(message="balance AI unavailable"))
        ]
    }
)(
    max_output_retries=0
);

sem pipeline_coordinator_narrative = "Mocked coordinator narrative failure for pipeline tests.";
def pipeline_coordinator_narrative(
    preparation: CoordinatorPreparation
) -> CoordinatorNarrative by MockLLM(
    model_name="mockllm",
    config={
        "outputs": [
            MockError(error=AuthenticationError(message="coordinator AI unavailable"))
        ]
    }
)(
    max_output_retries=0
);

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
    return response;
}

def remove_pipeline_test_student(student_id: str) {
    student = find_student(student_id);
    if student is not None {
        for task in [student->:HasAcademicTask:->] {
            del task;
        }
        for budget in [student->:HasBudget:->] {
            for expense in [budget->:HasExpense:->] {
                del expense;
            }
            del budget;
        }
        del student;
    }
}

def build_persisted_pipeline_snapshot(student_id: str) -> StudentSnapshot {
    remove_pipeline_test_student(student_id);
    _ = initialize_student(student_id, "Pipeline Test Student", "university", 5.0);
    student: Student | None = find_student(student_id);
    if student is None {
        raise RuntimeError("Pipeline test student initialization failed.");
    }
    _ = initialize_academic_task(
        student,
        "ml-assignment",
        "Machine Learning Assignment",
        "2026-10-18",
        40.0,
        3.0,
        5
    );
    _ = initialize_academic_task(
        student, "dsa-quiz", "DSA Quiz", "2026-10-19", 20.0, 2.0, 4
    );
    initialize_demo_finance(student);
    return build_student_snapshot(student_id);
}

test "pipeline consumes the persisted service snapshot contract" {
    student_id = "agent-pipeline-integration-fixture";
    snapshot = build_persisted_pipeline_snapshot(student_id);
    response = run_with_deterministic_fallback(snapshot);

    assert snapshot.profile.life_stage == "university";
    assert snapshot.academic_tasks[1].progress == 20.0;
    assert snapshot.academic_tasks[1].estimated_remaining_hours == 2.0;
    assert snapshot.academic_tasks[1].importance == 4;
    assert snapshot.finance.days_remaining == 4;
    assert response.academic.risk_level == RiskLevel.HIGH;
    assert "Machine Learning Assignment" in response.coordinator.next_action;
    remove_pipeline_test_student(student_id);
}

test "initial scenario produces a feasible ML assignment plan" {
    response = run_with_deterministic_fallback(build_demo_snapshot());

    assert response.academic.urgency == UrgencyLevel.HIGH;
    assert response.academic.risk_level == RiskLevel.HIGH;
    assert "Machine Learning Assignment" in response.academic.recommendation;
    assert "Machine Learning Assignment" in response.coordinator.next_action;
    assert response.balance.risk_level == RiskLevel.LOW;
    assert response.coordinator.daily_plan == [
        "Focus block 1: 1.50 hours on Machine Learning Assignment",
        "Break: 0.25 hours",
        "Focus block 2: 1.50 hours on Machine Learning Assignment"
    ];
}

test "progress increase lowers urgency and triggers replanning" {
    snapshot = build_demo_snapshot();
    initial = run_with_deterministic_fallback(snapshot);
    snapshot.academic_tasks[0].progress = 90.0;
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
    initial = run_with_deterministic_fallback(snapshot);
    snapshot.finance.remaining_budget -= 1000.0;
    snapshot.finance.spent_today += 1000.0;
    updated_facts = assess_finances(snapshot.finance);
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
    initial = run_with_deterministic_fallback(snapshot);
    snapshot.available_time.available_hours_today = 2.0;
    updated = run_with_deterministic_fallback(snapshot);

    assert initial.balance.risk_level == RiskLevel.LOW;
    assert updated.balance.risk_level == RiskLevel.CRITICAL;
    assert "defer the remainder" in updated.balance.recommendation;
    assert updated.coordinator.daily_plan != initial.coordinator.daily_plan;
    assert updated.coordinator.daily_plan == [
        "Focus block 1: 1.50 hours on Machine Learning Assignment",
        "Break: 0.25 hours",
        "Focus block 2: 0.05 hours on Machine Learning Assignment"
    ];
}

test "coordinator records and resolves a genuine schedule conflict" {
    snapshot = build_demo_snapshot();
    snapshot.academic_tasks[0].estimated_remaining_hours = 4.0;
    snapshot.available_time.available_hours_today = 3.0;
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
