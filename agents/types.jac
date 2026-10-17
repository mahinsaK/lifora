enum Domain: str { ACADEMIC = "ACADEMIC", FINANCE = "FINANCE", BALANCE = "BALANCE" }

enum UrgencyLevel: str {
    LOW = "LOW",
    MEDIUM = "MEDIUM",
    HIGH = "HIGH",
    CRITICAL = "CRITICAL"
}

enum RiskLevel: str {
    LOW = "LOW",
    MEDIUM = "MEDIUM",
    HIGH = "HIGH",
    CRITICAL = "CRITICAL"
}

obj Profile {
    has name: str,
        life_stage: str;
}

obj AcademicTask {
    has id: str,
        title: str,
        deadline: str,
        progress: float,
        estimated_remaining_hours: float,
        importance: int;
}

obj FinanceSnapshot {
    has weekly_budget: float,
        remaining_budget: float,
        spent_today: float,
        days_remaining: int;
}

obj AvailableTime {
    has available_hours_today: float;
}

obj StudentSnapshot {
    has profile: Profile,
        academic_tasks: list[AcademicTask],
        finance: FinanceSnapshot,
        available_time: AvailableTime,
        goals: list[str];
}

obj AgentResult {
    has domain: Domain,
        urgency: UrgencyLevel,
        risk_level: RiskLevel,
        summary: str,
        recommendation: str,
        reasoning: str,
        required_time: float;
}

obj CoordinatorResult {
    has next_action: str,
        daily_plan: list[str],
        finance_action: str,
        explanation: str,
        conflicts: list[str],
        deprioritized: list[str];
}
