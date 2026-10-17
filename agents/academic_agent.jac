import from jaclang.byllm.lib {
    AuthenticationError,
    ConfigurationError,
    FinishToolError,
    ModelNotFoundError,
    OutputConversionError,
    RateLimitError
}
import from agents.deadline_risk { assess_deadline_risk, hours_before_deadline }
import from services.state { AcademicTaskView as AcademicTask }
import from agents.types {
    AcademicAssessment,
    AgentResult,
    Domain,
    RiskLevel,
    SpecialistNarrative,
    UrgencyLevel
}

def risk_rank(risk: RiskLevel) -> int {
    if risk == RiskLevel.CRITICAL {
        return 4;
    }
    if risk == RiskLevel.HIGH {
        return 3;
    }
    if risk == RiskLevel.MEDIUM {
        return 2;
    }
    return 1;
}

def urgency_from_risk(risk: RiskLevel) -> UrgencyLevel {
    if risk == RiskLevel.CRITICAL {
        return UrgencyLevel.CRITICAL;
    }
    if risk == RiskLevel.HIGH {
        return UrgencyLevel.HIGH;
    }
    if risk == RiskLevel.MEDIUM {
        return UrgencyLevel.MEDIUM;
    }
    return UrgencyLevel.LOW;
}

def task_has_higher_priority(
    candidate: AcademicTask,
    candidate_risk: RiskLevel,
    candidate_hours_to_deadline: float,
    selected: AcademicTask,
    selected_risk: RiskLevel,
    selected_hours_to_deadline: float
) -> bool {
    if risk_rank(candidate_risk) != risk_rank(selected_risk) {
        return risk_rank(candidate_risk) > risk_rank(selected_risk);
    }
    if candidate_hours_to_deadline != selected_hours_to_deadline {
        return candidate_hours_to_deadline < selected_hours_to_deadline;
    }
    return candidate.importance > selected.importance;
}

def academic_next_action(
    task: AcademicTask, risk: RiskLevel, available_hours: float
) -> str {
    proposed_hours = min(task.estimated_remaining_hours, available_hours);
    if risk == RiskLevel.CRITICAL {
        return f"Start {task.title} now and use up to {proposed_hours:.1f} focused hours.";
    }
    return f"Continue {task.title} next for up to {proposed_hours:.1f} focused hours.";
}

def assess_academic_tasks(
    current_time: str, tasks: list[AcademicTask], available_hours: float
) -> AcademicAssessment {
    if available_hours < 0.0 {
        raise ValueError("available hours cannot be negative");
    }

    selected: AcademicTask | None = None;
    selected_risk: RiskLevel = RiskLevel.LOW;
    selected_hours_to_deadline: float = 0.0;

    for task in tasks {
        task_risk = assess_deadline_risk(
            current_time,
            task.deadline,
            task.progress,
            task.estimated_remaining_hours,
            available_hours,
            task.importance
        );
        task_hours_to_deadline = hours_before_deadline(current_time, task.deadline);

        if task.progress == 100.0 or task.estimated_remaining_hours == 0.0 {
            continue;
        }

        if selected is None {
            selected = task;
            selected_risk = task_risk;
            selected_hours_to_deadline = task_hours_to_deadline;
        } elif task_has_higher_priority(
            task,
            task_risk,
            task_hours_to_deadline,
            selected,
            selected_risk,
            selected_hours_to_deadline
        ) {
            selected = task;
            selected_risk = task_risk;
            selected_hours_to_deadline = task_hours_to_deadline;
        }
    }

    if selected is None {
        return AcademicAssessment(
            risk_level=RiskLevel.LOW,
            urgency=UrgencyLevel.LOW,
            most_urgent_task_id="",
            most_urgent_task_title="",
            required_time=0.0,
            candidate_next_action="No unfinished academic task requires action."
        );
    }

    return AcademicAssessment(
        risk_level=selected_risk,
        urgency=urgency_from_risk(selected_risk),
        most_urgent_task_id=selected.id,
        most_urgent_task_title=selected.title,
        required_time=selected.estimated_remaining_hours,
        candidate_next_action=academic_next_action(
            selected, selected_risk, available_hours
        )
    );
}

sem generate_academic_narrative = """
Write a concise academic summary, recommendation, and evidence-based explanation.
Use only the supplied deterministic assessment. Preserve its selected task, risk,
urgency, required time, and candidate next action; do not recalculate them.
""";

def generate_academic_narrative(assessment: AcademicAssessment) -> SpecialistNarrative by llm(
    temperature=0.0, max_output_retries=1
);

def fallback_academic_narrative(assessment: AcademicAssessment) -> SpecialistNarrative {
    if assessment.most_urgent_task_id == "" {
        return SpecialistNarrative(
            summary="No unfinished academic task needs attention.",
            recommendation=assessment.candidate_next_action,
            explanation="The deterministic assessment found no remaining academic work; AI reasoning was unavailable."
        );
    }
    return SpecialistNarrative(
        summary=f"{assessment.most_urgent_task_title} has {assessment.risk_level} deadline risk.",
        recommendation=assessment.candidate_next_action,
        explanation=f"It is the highest-ranked unfinished task and needs {assessment.required_time:.1f} hours; AI reasoning was unavailable."
    );
}

def build_academic_result(
    assessment: AcademicAssessment, narrative: SpecialistNarrative
) -> AgentResult {
    return AgentResult(
        domain=Domain.ACADEMIC,
        urgency=assessment.urgency,
        risk_level=assessment.risk_level,
        summary=narrative.summary,
        recommendation=narrative.recommendation,
        reasoning=narrative.explanation,
        required_time=assessment.required_time
    );
}

def run_academic_agent(
    current_time: str,
    tasks: list[AcademicTask],
    available_hours: float,
    narrative_generator:
        Callable[
            [AcademicAssessment],
            SpecialistNarrative
        ] = generate_academic_narrative
) -> AgentResult {
    assessment = assess_academic_tasks(current_time, tasks, available_hours);
    narrative = fallback_academic_narrative(assessment);
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
    return build_academic_result(assessment, narrative);
}
