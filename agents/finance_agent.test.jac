import pytest;
import from jaclang.byllm.lib { MockError, MockLLM, ModelNotFoundError, RateLimitError }
import from agents.mock_snapshot { build_demo_snapshot }
import from agents.test_support { build_mock_llm }

glob llm = build_mock_llm(outputs=[]);

test "finance assessment calculates the documented demo budget" {
    snapshot = build_demo_snapshot();
    assessment = assess_finances(snapshot.finance);

    assert assessment.total_spent == 3500.0;
    assert assessment.remaining_budget == 3500.0;
    assert assessment.recommended_daily_allowance == 875.0;
    assert assessment.budget_pressure == RiskLevel.HIGH;
    assert assessment.urgency == UrgencyLevel.HIGH;
}

test "healthy spending produces low finance pressure" {
    assessment = assess_finances(
        FinanceSnapshot(
            weekly_budget=7000.0,
            remaining_budget=5600.0,
            spent_today=200.0,
            days_remaining=4
        )
    );

    assert assessment.total_spent == 1400.0;
    assert assessment.recommended_daily_allowance == 1400.0;
    assert assessment.budget_pressure == RiskLevel.LOW;
    assert assessment.urgency == UrgencyLevel.LOW;
}

test "large added expense escalates demo pressure to critical" {
    snapshot = build_demo_snapshot();
    snapshot.finance.remaining_budget -= 1000.0;
    snapshot.finance.spent_today += 1000.0;
    assessment = assess_finances(snapshot.finance);

    assert assessment.total_spent == 4500.0;
    assert assessment.remaining_budget == 2500.0;
    assert assessment.recommended_daily_allowance == 625.0;
    assert assessment.budget_pressure == RiskLevel.CRITICAL;
    assert assessment.urgency == UrgencyLevel.CRITICAL;
    assert "Pause optional spending" in assessment.candidate_next_action;
}

test "overspending produces critical finance pressure" {
    assessment = assess_finances(
        FinanceSnapshot(
            weekly_budget=7000.0,
            remaining_budget=-100.0,
            spent_today=1000.0,
            days_remaining=2
        )
    );

    assert assessment.total_spent == 7100.0;
    assert assessment.recommended_daily_allowance == 0.0;
    assert assessment.budget_pressure == RiskLevel.CRITICAL;
    assert assessment.urgency == UrgencyLevel.CRITICAL;
}

test "inconsistent finance inputs are rejected" {
    with pytest.raises(ValueError) {
        assess_finances(
            FinanceSnapshot(
                weekly_budget=1000.0,
                remaining_budget=800.0,
                spent_today=300.0,
                days_remaining=3
            )
        );
    }
    with pytest.raises(ValueError) {
        assess_finances(
            FinanceSnapshot(
                weekly_budget=1000.0,
                remaining_budget=500.0,
                spent_today=-1.0,
                days_remaining=3
            )
        );
    }
}

test "finance result keeps deterministic fields locked" {
    snapshot = build_demo_snapshot();
    assessment = assess_finances(snapshot.finance);
    narrative = SpecialistNarrative(
        summary="Narrative summary",
        recommendation="Narrative recommendation",
        explanation="Narrative explanation"
    );
    result = build_finance_result(assessment, narrative);

    assert result.domain == Domain.FINANCE;
    assert result.risk_level == assessment.budget_pressure;
    assert result.urgency == assessment.urgency;
    assert result.required_time == 0.0;
    assert result.summary == "Narrative summary";
}

test "finance agent uses byLLM only for narrative fields" {
    llm.config["outputs"] = [
            SpecialistNarrative(
                summary="Today's spending creates high budget pressure.",
                recommendation="Reduce optional spending for the rest of the week.",
                explanation="Today's spending is above the calculated daily allowance."
            )
        ];
    snapshot = build_demo_snapshot();
    result = run_finance_agent(snapshot.finance);

    assert result.domain == Domain.FINANCE;
    assert result.risk_level == RiskLevel.HIGH;
    assert result.urgency == UrgencyLevel.HIGH;
    assert result.required_time == 0.0;
    assert result.summary == "Today's spending creates high budget pressure.";
    assert len(llm.config["outputs"]) == 0;
}

test "finance agent falls back after rate-limit failure" {
    llm.config["outputs"] = [
        MockError(error=RateLimitError(message="test rate limit failure"))
    ];
    snapshot = build_demo_snapshot();
    result = run_finance_agent(snapshot.finance);

    assert result.risk_level == RiskLevel.HIGH;
    assert result.urgency == UrgencyLevel.HIGH;
    assert result.required_time == 0.0;
    assert "AI reasoning was unavailable" in result.reasoning;
    assert len(llm.config["outputs"]) == 0;
}

test "finance agent falls back after missing-model failure" {
    llm.config["outputs"] = [
        MockError(error=ModelNotFoundError(message="test model failure"))
    ];
    snapshot = build_demo_snapshot();
    result = run_finance_agent(snapshot.finance);

    assert result.risk_level == RiskLevel.HIGH;
    assert result.urgency == UrgencyLevel.HIGH;
    assert result.required_time == 0.0;
    assert "AI reasoning was unavailable" in result.reasoning;
    assert len(llm.config["outputs"]) == 0;
}
