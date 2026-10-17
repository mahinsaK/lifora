import from jaclang.byllm.lib {
    AuthenticationError,
    ConfigurationError,
    FinishToolError,
    ModelNotFoundError,
    OutputConversionError,
    RateLimitError
}
import from services.state { FinanceView as FinanceSnapshot }
import from agents.types {
    AgentResult,
    Domain,
    FinanceAssessment,
    RiskLevel,
    SpecialistNarrative,
    UrgencyLevel
}

def validate_finance_snapshot(finance: FinanceSnapshot) {
    if finance.weekly_budget < 0.0 {
        raise ValueError("weekly budget cannot be negative");
    }
    if finance.remaining_budget > finance.weekly_budget {
        raise ValueError("remaining budget cannot exceed weekly budget");
    }
    if finance.spent_today < 0.0 {
        raise ValueError("spent today cannot be negative");
    }
    if finance.days_remaining < 0 {
        raise ValueError("days remaining cannot be negative");
    }
    total_spent = finance.weekly_budget - finance.remaining_budget;
    if finance.spent_today > total_spent {
        raise ValueError("spent today cannot exceed total weekly spending");
    }
}

def finance_urgency_from_pressure(pressure: RiskLevel) -> UrgencyLevel {
    if pressure == RiskLevel.CRITICAL {
        return UrgencyLevel.CRITICAL;
    }
    if pressure == RiskLevel.HIGH {
        return UrgencyLevel.HIGH;
    }
    if pressure == RiskLevel.MEDIUM {
        return UrgencyLevel.MEDIUM;
    }
    return UrgencyLevel.LOW;
}

def calculate_budget_pressure(
    weekly_budget: float,
    remaining_budget: float,
    spent_today: float,
    days_remaining: int,
    daily_allowance: float
) -> RiskLevel {
    if remaining_budget < 0.0 {
        return RiskLevel.CRITICAL;
    }
    if days_remaining == 0 {
        return RiskLevel.LOW;
    }
    if remaining_budget == 0.0 {
        return RiskLevel.CRITICAL;
    }

    if daily_allowance > 0.0 and spent_today >= daily_allowance * 3.0 {
        return RiskLevel.CRITICAL;
    }
    if spent_today > daily_allowance {
        return RiskLevel.HIGH;
    }
    if weekly_budget > 0.0 and remaining_budget / weekly_budget <= 0.2 {
        return RiskLevel.HIGH;
    }
    if weekly_budget > 0.0 and remaining_budget / weekly_budget <= 0.5 {
        return RiskLevel.MEDIUM;
    }
    if spent_today >= daily_allowance * 0.75 {
        return RiskLevel.MEDIUM;
    }
    return RiskLevel.LOW;
}

def finance_next_action(pressure: RiskLevel, daily_allowance: float) -> str {
    if pressure == RiskLevel.CRITICAL {
        return "Pause optional spending and review the remaining essential costs.";
    }
    if pressure == RiskLevel.HIGH {
        return f"Reduce optional spending and keep future daily spending within {daily_allowance:.2f}.";
    }
    if pressure == RiskLevel.MEDIUM {
        return f"Use {daily_allowance:.2f} as the daily spending ceiling.";
    }
    return f"Keep daily spending within the {daily_allowance:.2f} allowance.";
}

def assess_finances(finance: FinanceSnapshot) -> FinanceAssessment {
    validate_finance_snapshot(finance);
    total_spent = finance.weekly_budget - finance.remaining_budget;
    daily_allowance = 0.0;
    if finance.days_remaining > 0 and finance.remaining_budget > 0.0 {
        daily_allowance = finance.remaining_budget / float(finance.days_remaining);
    }
    pressure = calculate_budget_pressure(
        finance.weekly_budget,
        finance.remaining_budget,
        finance.spent_today,
        finance.days_remaining,
        daily_allowance
    );
    return FinanceAssessment(
        total_spent=total_spent,
        remaining_budget=finance.remaining_budget,
        recommended_daily_allowance=daily_allowance,
        budget_pressure=pressure,
        urgency=finance_urgency_from_pressure(pressure),
        candidate_next_action=finance_next_action(pressure, daily_allowance)
    );
}

sem generate_finance_narrative = """
Write a concise finance summary, recommendation, and evidence-based explanation.
Use only the supplied deterministic assessment. Preserve total spent, remaining
budget, daily allowance, budget pressure, urgency, and candidate next action.
Do not recalculate values and do not provide investment, trading, gambling,
credit, or loan advice.
""";

def generate_finance_narrative(assessment: FinanceAssessment) -> SpecialistNarrative by llm(
    temperature=0.0, max_output_retries=1
);

def fallback_finance_narrative(assessment: FinanceAssessment) -> SpecialistNarrative {
    return SpecialistNarrative(
        summary=f"Budget pressure is {assessment.budget_pressure} with {assessment.remaining_budget:.2f} remaining.",
        recommendation=assessment.candidate_next_action,
        explanation=f"Total spending is {assessment.total_spent:.2f} and the recommended daily allowance is {assessment.recommended_daily_allowance:.2f}; AI reasoning was unavailable."
    );
}

def build_finance_result(
    assessment: FinanceAssessment, narrative: SpecialistNarrative
) -> AgentResult {
    return AgentResult(
        domain=Domain.FINANCE,
        urgency=assessment.urgency,
        risk_level=assessment.budget_pressure,
        summary=narrative.summary,
        recommendation=narrative.recommendation,
        reasoning=narrative.explanation,
        required_time=0.0
    );
}

def run_finance_agent(
    finance: FinanceSnapshot,
    narrative_generator:
        Callable[[FinanceAssessment], SpecialistNarrative] = generate_finance_narrative
) -> AgentResult {
    assessment = assess_finances(finance);
    narrative = fallback_finance_narrative(assessment);
    try {
        narrative = narrative_generator(assessment);
    } except (
        AuthenticationError,
        RateLimitError,
        ModelNotFoundError,
        ConfigurationError,
        OutputConversionError,
        FinishToolError
    ) {}
    return build_finance_result(assessment, narrative);
}
