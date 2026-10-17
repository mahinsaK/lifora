import from math { ceil }
import from jaclang.byllm.lib {
    AuthenticationError,
    ConfigurationError,
    FinishToolError,
    ModelNotFoundError,
    OutputConversionError,
    RateLimitError
}
import from agents.types {
    AgentResult,
    BalanceAssessment,
    Domain,
    RiskLevel,
    SpecialistNarrative,
    UrgencyLevel
}

glob FOCUS_BLOCK_HOURS = 1.5,
     BREAK_HOURS = 0.25,
     BUFFER_RATIO = 0.1,
     MAX_BUFFER_HOURS = 0.5;

def validate_balance_inputs(proposed_work_hours: float, available_hours: float) {
    if proposed_work_hours < 0.0 {
        raise ValueError("proposed work hours cannot be negative");
    }
    if available_hours < 0.0 {
        raise ValueError("available hours cannot be negative");
    }
}

def calculate_buffer_hours(available_hours: float) -> float {
    return min(MAX_BUFFER_HOURS, available_hours * BUFFER_RATIO);
}

def calculate_break_hours(proposed_work_hours: float) -> float {
    if proposed_work_hours <= FOCUS_BLOCK_HOURS {
        return 0.0;
    }
    focus_blocks = ceil(proposed_work_hours / FOCUS_BLOCK_HOURS);
    return float(focus_blocks - 1) * BREAK_HOURS;
}

def calculate_maximum_focused_hours(available_hours: float) -> float {
    buffer_hours = calculate_buffer_hours(available_hours);
    remaining_schedule_hours = available_hours - buffer_hours;
    focused_hours = 0.0;

    while remaining_schedule_hours > 0.0 {
        focus_block = min(FOCUS_BLOCK_HOURS, remaining_schedule_hours);
        focused_hours += focus_block;
        remaining_schedule_hours -= focus_block;

        if remaining_schedule_hours <= BREAK_HOURS {
            break;
        }
        remaining_schedule_hours -= BREAK_HOURS;
    }
    return focused_hours;
}

def balance_urgency_from_pressure(pressure: RiskLevel) -> UrgencyLevel {
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

def calculate_scheduling_pressure(
    proposed_work_hours: float,
    available_hours: float,
    maximum_focused_hours: float,
    fits_available_time: bool
) -> RiskLevel {
    if proposed_work_hours == 0.0 {
        return RiskLevel.LOW;
    }
    if proposed_work_hours > available_hours {
        return RiskLevel.CRITICAL;
    }
    if not fits_available_time {
        return RiskLevel.HIGH;
    }
    if proposed_work_hours >= maximum_focused_hours * 0.8 {
        return RiskLevel.MEDIUM;
    }
    return RiskLevel.LOW;
}

def balance_next_action(
    proposed_work_hours: float,
    fits_available_time: bool,
    maximum_focused_hours: float,
    break_hours: float,
    buffer_hours: float
) -> str {
    if proposed_work_hours == 0.0 {
        return "Keep the available time unscheduled for recovery or new priorities.";
    }
    if not fits_available_time {
        return f"Limit focused work to {maximum_focused_hours:.1f} hours and defer the remainder.";
    }
    if break_hours > 0.0 {
        return f"Split {proposed_work_hours:.1f} focused hours into blocks with {break_hours:.2f} hours of breaks and a {buffer_hours:.2f}-hour buffer.";
    }
    return f"Schedule one {proposed_work_hours:.1f}-hour focus block and preserve a {buffer_hours:.2f}-hour buffer.";
}

def assess_balance(
    proposed_work_hours: float, available_hours: float
) -> BalanceAssessment {
    validate_balance_inputs(proposed_work_hours, available_hours);
    buffer_hours = calculate_buffer_hours(available_hours);
    break_hours = calculate_break_hours(proposed_work_hours);
    maximum_focused_hours = calculate_maximum_focused_hours(available_hours);
    fits_available_time = (
        proposed_work_hours + break_hours + buffer_hours <= available_hours
        and proposed_work_hours <= maximum_focused_hours
    );
    pressure = calculate_scheduling_pressure(
        proposed_work_hours, available_hours, maximum_focused_hours, fits_available_time
    );
    return BalanceAssessment(
        proposed_work_hours=proposed_work_hours,
        fits_available_time=fits_available_time,
        maximum_realistic_focused_hours=maximum_focused_hours,
        required_break_hours=break_hours,
        required_buffer_hours=buffer_hours,
        scheduling_pressure=pressure,
        urgency=balance_urgency_from_pressure(pressure),
        candidate_next_action=balance_next_action(
            proposed_work_hours,
            fits_available_time,
            maximum_focused_hours,
            break_hours,
            buffer_hours
        )
    );
}

sem generate_balance_narrative = """
Write a concise workload-balance summary, recommendation, and evidence-based
explanation. Use only the supplied deterministic assessment. Preserve whether
the proposal fits, maximum focused work, breaks, buffer, scheduling pressure,
urgency, and candidate next action. Explicitly state a constraint when the
proposed work does not fit. Do not make medical or mental-health diagnoses.
""";

def generate_balance_narrative(assessment: BalanceAssessment) -> SpecialistNarrative by llm(
    temperature=0.0, max_output_retries=1
);

def fallback_balance_narrative(assessment: BalanceAssessment) -> SpecialistNarrative {
    fit_label = "fits" if assessment.fits_available_time else "does not fit";
    return SpecialistNarrative(
        summary=f"The proposed work {fit_label} the realistic schedule capacity.",
        recommendation=assessment.candidate_next_action,
        explanation=f"Maximum focused work is {assessment.maximum_realistic_focused_hours:.1f} hours with {assessment.required_break_hours:.2f} break hours and a {assessment.required_buffer_hours:.2f}-hour buffer; AI reasoning was unavailable."
    );
}

def build_balance_result(
    assessment: BalanceAssessment, narrative: SpecialistNarrative
) -> AgentResult {
    return AgentResult(
        domain=Domain.BALANCE,
        urgency=assessment.urgency,
        risk_level=assessment.scheduling_pressure,
        summary=narrative.summary,
        recommendation=narrative.recommendation,
        reasoning=narrative.explanation,
        required_time=assessment.maximum_realistic_focused_hours
    );
}

def run_balance_agent(
    proposed_work_hours: float,
    available_hours: float,
    narrative_generator:
        Callable[[BalanceAssessment], SpecialistNarrative] = generate_balance_narrative
) -> AgentResult {
    assessment = assess_balance(proposed_work_hours, available_hours);
    narrative = fallback_balance_narrative(assessment);
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
    return build_balance_result(assessment, narrative);
}
