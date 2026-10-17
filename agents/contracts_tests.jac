import from agents.types {
    AgentResult,
    CoordinatorResult,
    Domain,
    RiskLevel,
    UrgencyLevel
}

test "bounded contract values remain wire friendly" {
    assert Domain.ACADEMIC == "ACADEMIC";
    assert UrgencyLevel.HIGH == "HIGH";
    assert RiskLevel.CRITICAL == "CRITICAL";
}

test "agent result preserves its structured contract" {
    result = AgentResult(
        domain=Domain.ACADEMIC,
        urgency=UrgencyLevel.HIGH,
        risk_level=RiskLevel.CRITICAL,
        summary="An urgent assignment needs attention.",
        recommendation="Continue the ML assignment.",
        reasoning="The deadline is tomorrow.",
        required_time=3.0
    );

    assert result.domain == Domain.ACADEMIC;
    assert result.urgency == UrgencyLevel.HIGH;
    assert result.risk_level == RiskLevel.CRITICAL;
    assert result.required_time == 3.0;
}

test "coordinator result keeps trace collections separate" {
    result = CoordinatorResult(
        next_action="Continue the ML assignment.",
        daily_plan=["Study block", "Break"],
        finance_action="Avoid optional spending today.",
        explanation="The nearest deadline has the highest consequence.",
        conflicts=["Academic workload exceeds one continuous focus block."],
        deprioritized=["DSA review follows the assignment block."]
    );

    assert len(result.daily_plan) == 2;
    assert len(result.conflicts) == 1;
    assert len(result.deprioritized) == 1;
}
