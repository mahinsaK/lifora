import from jaclang.byllm.lib {
    AuthenticationError,
    MockError,
    MockLLM,
    MockRawResponse
}
import from agents.mock_snapshot { build_demo_snapshot }

glob llm = MockLLM(outputs=[]),
     FIXED_ACADEMIC_NOW = "2026-10-17T18:00:00+05:30";

test "academic assessment selects the most urgent unfinished task" {
    snapshot = build_demo_snapshot();
    assessment = assess_academic_tasks(
        FIXED_ACADEMIC_NOW,
        snapshot.academic_tasks,
        snapshot.available_time.available_hours_today
    );

    assert assessment.most_urgent_task_id == "ml-assignment";
    assert assessment.risk_level == RiskLevel.HIGH;
    assert assessment.urgency == UrgencyLevel.HIGH;
    assert assessment.required_time == 3.0;
    assert "ML Assignment" in assessment.candidate_next_action;
}

test "completed tasks are excluded from academic priority" {
    snapshot = build_demo_snapshot();
    snapshot.academic_tasks[0].progress = 100.0;
    snapshot.academic_tasks[0].estimated_remaining_hours = 0.0;

    assessment = assess_academic_tasks(
        FIXED_ACADEMIC_NOW,
        snapshot.academic_tasks,
        snapshot.available_time.available_hours_today
    );

    assert assessment.most_urgent_task_id == "dsa-quiz";
    assert assessment.required_time == 2.0;
}

test "academic result keeps deterministic fields locked" {
    snapshot = build_demo_snapshot();
    assessment = assess_academic_tasks(
        FIXED_ACADEMIC_NOW,
        snapshot.academic_tasks,
        snapshot.available_time.available_hours_today
    );
    narrative = SpecialistNarrative(
        summary="Narrative summary",
        recommendation="Narrative recommendation",
        explanation="Narrative explanation"
    );
    result = build_academic_result(assessment, narrative);

    assert result.domain == Domain.ACADEMIC;
    assert result.risk_level == assessment.risk_level;
    assert result.urgency == assessment.urgency;
    assert result.required_time == assessment.required_time;
    assert result.summary == "Narrative summary";
}

test "academic agent uses byLLM only for narrative fields" {
    llm = MockLLM(
        outputs=[
            {
                "summary": "The ML assignment has the strongest deadline pressure.",
                "recommendation": "Start the ML assignment now.",
                "explanation": "It is due first, has three hours remaining, and is only 40 percent complete."
            }
        ]
    );
    snapshot = build_demo_snapshot();
    result = run_academic_agent(
        FIXED_ACADEMIC_NOW,
        snapshot.academic_tasks,
        snapshot.available_time.available_hours_today
    );

    assert result.domain == Domain.ACADEMIC;
    assert result.risk_level == RiskLevel.HIGH;
    assert result.urgency == UrgencyLevel.HIGH;
    assert result.required_time == 3.0;
    assert result.summary == "The ML assignment has the strongest deadline pressure.";
    assert llm.exhausted();
}

test "academic agent falls back after authentication failure" {
    llm = MockLLM(
        outputs=[MockError(error=AuthenticationError(message="test API key failure"))]
    );
    snapshot = build_demo_snapshot();
    result = run_academic_agent(
        FIXED_ACADEMIC_NOW,
        snapshot.academic_tasks,
        snapshot.available_time.available_hours_today
    );

    assert result.risk_level == RiskLevel.HIGH;
    assert result.urgency == UrgencyLevel.HIGH;
    assert result.required_time == 3.0;
    assert "AI reasoning was unavailable" in result.reasoning;
    assert llm.exhausted();
}

test "academic agent falls back after typed output conversion failure" {
    llm = MockLLM(outputs=[MockRawResponse(content="{"), MockRawResponse(content="{")]);
    snapshot = build_demo_snapshot();
    result = run_academic_agent(
        FIXED_ACADEMIC_NOW,
        snapshot.academic_tasks,
        snapshot.available_time.available_hours_today
    );

    assert result.risk_level == RiskLevel.HIGH;
    assert result.urgency == UrgencyLevel.HIGH;
    assert result.required_time == 3.0;
    assert "AI reasoning was unavailable" in result.reasoning;
    assert llm.exhausted();
}

test "academic agent does not silently catch unrelated failures" {
    llm = MockLLM(outputs=[MockError(error=ValueError("unexpected test failure"))]);
    snapshot = build_demo_snapshot();

    with testraises(ValueError) {
        run_academic_agent(
            FIXED_ACADEMIC_NOW,
            snapshot.academic_tasks,
            snapshot.available_time.available_hours_today
        );
    }
}
