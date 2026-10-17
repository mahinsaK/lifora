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

obj SpecialistNarrative {
    has summary: str,
        recommendation: str,
        explanation: str;
}

obj AcademicAssessment {
    has risk_level: RiskLevel,
        urgency: UrgencyLevel,
        most_urgent_task_id: str,
        most_urgent_task_title: str,
        required_time: float,
        candidate_next_action: str;
}

obj FinanceAssessment {
    has total_spent: float,
        remaining_budget: float,
        recommended_daily_allowance: float,
        budget_pressure: RiskLevel,
        urgency: UrgencyLevel,
        candidate_next_action: str;
}

obj BalanceAssessment {
    has proposed_work_hours: float,
        fits_available_time: bool,
        maximum_realistic_focused_hours: float,
        required_break_hours: float,
        required_buffer_hours: float,
        scheduling_pressure: RiskLevel,
        urgency: UrgencyLevel,
        candidate_next_action: str;
}

obj CoordinatorPreparation {
    has ranked_domains: list[Domain],
        candidate_actions: list[str],
        candidate_work_blocks: list[str],
        conflicts: list[str],
        finance_action: str,
        fallback_next_action: str,
        fallback_daily_plan: list[str],
        fallback_explanation: str,
        fallback_deprioritized: list[str];
}

obj CoordinatorNarrative {
    has next_action: str,
        daily_plan: list[str],
        explanation: str,
        deprioritized: list[str];
}
