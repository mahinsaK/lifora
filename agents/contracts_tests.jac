import from agents.types {
    AgentResult,
    CoordinatorResult,
    Domain,
    PlanningResponse,
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

test "planning response exposes specialists and coordinator" {
    academic = AgentResult(
        domain=Domain.ACADEMIC,
        urgency=UrgencyLevel.CRITICAL,
        risk_level=RiskLevel.CRITICAL,
        summary="Assignment deadline is at risk.",
        recommendation="Complete the assignment first.",
        reasoning="Remaining work exceeds the available study time.",
        required_time=4.0
    );
    finance = AgentResult(
        domain=Domain.FINANCE,
        urgency=UrgencyLevel.MEDIUM,
        risk_level=RiskLevel.MEDIUM,
        summary="Spending is above the daily allowance.",
        recommendation="Limit discretionary spending today.",
        reasoning="The remaining budget must cover the rest of the week.",
        required_time=0.0
    );
    balance = AgentResult(
        domain=Domain.BALANCE,
        urgency=UrgencyLevel.HIGH,
        risk_level=RiskLevel.HIGH,
        summary="The proposed work does not fit the available time.",
        recommendation="Use focused blocks with breaks and a buffer.",
        reasoning="A reduced schedule is more realistic today.",
        required_time=3.0
    );
    coordinator = CoordinatorResult(
        next_action="Start the assignment's highest-value section.",
        daily_plan=["90-minute assignment block", "15-minute break"],
        finance_action="Limit discretionary spending today.",
        explanation="The assignment is the highest-risk feasible action.",
        conflicts=["Academic requested four hours; balance allows three."],
        deprioritized=["Optional reading postponed until tomorrow."]
    );

    response = PlanningResponse(
        academic=academic, finance=finance, balance=balance, coordinator=coordinator
    );

    assert response.academic.domain == Domain.ACADEMIC;
    assert response.finance.domain == Domain.FINANCE;
    assert response.balance.domain == Domain.BALANCE;
    assert response.academic.reasoning == academic.reasoning;
    assert response.finance.recommendation == finance.recommendation;
    assert response.balance.required_time == balance.required_time;
    assert response.coordinator.next_action == coordinator.next_action;
    assert response.coordinator.conflicts == coordinator.conflicts;
    assert response.coordinator.deprioritized == coordinator.deprioritized;
}
