import from jaclang.byllm.lib {
    ConfigurationError,
    FinishToolError,
    MockError,
    MockLLM
}
import from agents.academic_agent { assess_academic_tasks }
import from agents.mock_snapshot { build_demo_snapshot }
import from test_support { assert_value_error }

glob FIXED_BALANCE_NOW = "2026-10-17T18:00:00+05:30";

sem test_balance_success_narrative = "Mocked balance narrative for unit tests.";
def test_balance_success_narrative(
    assessment: BalanceAssessment
) -> SpecialistNarrative by MockLLM(
    model_name="mockllm",
    config={
        "outputs": [
            SpecialistNarrative(
                summary="The proposed workload exceeds realistic focus capacity.",
                recommendation="Reduce the work block and defer the remainder.",
                explanation="The proposal does not fit after breaks and buffer time."
            )
        ]
    }
)();

sem test_balance_configuration_failure = "Mocked balance configuration failure.";
def test_balance_configuration_failure(
    assessment: BalanceAssessment
) -> SpecialistNarrative by MockLLM(
    model_name="mockllm",
    config={
        "outputs": [
            MockError(error=ConfigurationError(message="test configuration failure"))
        ]
    }
)();

sem test_balance_finish_tool_failure = "Mocked balance finish-tool failure.";
def test_balance_finish_tool_failure(
    assessment: BalanceAssessment
) -> SpecialistNarrative by MockLLM(
    model_name="mockllm",
    config={
        "outputs": [
            MockError(error=FinishToolError(message="test finish-tool failure"))
        ]
    }
)();

test "work fitting the evening includes breaks and buffer" {
    assessment = assess_balance(3.0, 5.0);

    assert assessment.fits_available_time;
    assert abs(assessment.maximum_realistic_focused_hours - 4.0) < 0.001;
    assert abs(assessment.required_break_hours - 0.25) < 0.001;
    assert abs(assessment.required_buffer_hours - 0.5) < 0.001;
    assert assessment.scheduling_pressure == RiskLevel.LOW;
    assert assessment.urgency == UrgencyLevel.LOW;
}

test "work exceeding available time is critical" {
    assessment = assess_balance(4.0, 3.0);

    assert not assessment.fits_available_time;
    assert abs(assessment.maximum_realistic_focused_hours - 2.45) < 0.001;
    assert abs(assessment.required_break_hours - 0.5) < 0.001;
    assert abs(assessment.required_buffer_hours - 0.3) < 0.001;
    assert assessment.scheduling_pressure == RiskLevel.CRITICAL;
    assert assessment.urgency == UrgencyLevel.CRITICAL;
    assert "defer the remainder" in assessment.candidate_next_action;
}

test "a nearly full but feasible schedule has medium pressure" {
    assessment = assess_balance(2.4, 3.0);

    assert assessment.fits_available_time;
    assert assessment.scheduling_pressure == RiskLevel.MEDIUM;
    assert assessment.urgency == UrgencyLevel.MEDIUM;
}

test "invalid balance hours are rejected" {
    assert_value_error(lambda { assess_balance(-1.0, 3.0); });
    assert_value_error(lambda { assess_balance(1.0, -3.0); });
}

test "balance assessment can disagree with academic required time" {
    snapshot = build_demo_snapshot();
    snapshot.academic_tasks[0].estimated_remaining_hours = 4.0;
    academic = assess_academic_tasks(FIXED_BALANCE_NOW, snapshot.academic_tasks, 3.0);
    balance = assess_balance(academic.required_time, 3.0);

    assert academic.required_time == 4.0;
    assert not balance.fits_available_time;
    assert balance.maximum_realistic_focused_hours < academic.required_time;
    assert "defer the remainder" in balance.candidate_next_action;
}

test "balance result keeps deterministic fields locked" {
    assessment = assess_balance(4.0, 3.0);
    narrative = SpecialistNarrative(
        summary="Narrative summary",
        recommendation="Narrative recommendation",
        explanation="Narrative explanation"
    );
    result = build_balance_result(assessment, narrative);

    assert result.domain == Domain.BALANCE;
    assert result.risk_level == assessment.scheduling_pressure;
    assert result.urgency == assessment.urgency;
    assert result.required_time == assessment.maximum_realistic_focused_hours;
    assert result.summary == "Narrative summary";
}

test "balance agent uses byLLM only for narrative fields" {
    result = run_balance_agent(4.0, 3.0, test_balance_success_narrative);

    assert result.domain == Domain.BALANCE;
    assert result.risk_level == RiskLevel.CRITICAL;
    assert result.urgency == UrgencyLevel.CRITICAL;
    assert abs(result.required_time - 2.45) < 0.001;
    assert result.summary == "The proposed workload exceeds realistic focus capacity.";
}

test "balance agent falls back after configuration failure" {
    result = run_balance_agent(4.0, 3.0, test_balance_configuration_failure);

    assert result.risk_level == RiskLevel.CRITICAL;
    assert result.urgency == UrgencyLevel.CRITICAL;
    assert abs(result.required_time - 2.45) < 0.001;
    assert "AI reasoning was unavailable" in result.reasoning;
}

test "balance agent falls back after finish-tool failure" {
    result = run_balance_agent(4.0, 3.0, test_balance_finish_tool_failure);

    assert result.risk_level == RiskLevel.CRITICAL;
    assert result.urgency == UrgencyLevel.CRITICAL;
    assert abs(result.required_time - 2.45) < 0.001;
    assert "AI reasoning was unavailable" in result.reasoning;
}
