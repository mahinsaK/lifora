import from datetime { datetime }
import from jaclang.byllm.lib {
    AuthenticationError,
    ConfigurationError,
    FinishToolError,
    ModelNotFoundError,
    OutputConversionError,
    RateLimitError
}
import from agents.balance_agent { assess_balance }
import from agents.deadline_risk { validate_deadline_inputs }
import from agents.finance_agent { assess_finances }
import from services.snapshot { StudentSnapshot }
import from services.state { AcademicTaskView as AcademicTask }
import from agents.types {
    AgentResult,
    CoordinatorNarrative,
    CoordinatorPreparation,
    CoordinatorResult,
    Domain,
    RiskLevel,
    UrgencyLevel
}

glob COORDINATOR_FOCUS_BLOCK_HOURS = 1.5,
     COORDINATOR_BREAK_HOURS = 0.25;

def coordinator_level_rank(level: str) -> int {
    if level == RiskLevel.CRITICAL or level == UrgencyLevel.CRITICAL {
        return 4;
    }
    if level == RiskLevel.HIGH or level == UrgencyLevel.HIGH {
        return 3;
    }
    if level == RiskLevel.MEDIUM or level == UrgencyLevel.MEDIUM {
        return 2;
    }
    return 1;
}

def coordinator_priority_score(result: AgentResult) -> int {
    return coordinator_level_rank(result.risk_level) * 10
        + coordinator_level_rank(result.urgency);
}

def rank_specialists(
    academic: AgentResult, finance: AgentResult, balance: AgentResult
) -> list[Domain] {
    ranked = [academic, finance, balance];
    for i in range(len(ranked)) {
        for j in range(i + 1, len(ranked)) {
            if coordinator_priority_score(ranked[j])
                > coordinator_priority_score(ranked[i]) {
                current = ranked[i];
                ranked[i] = ranked[j];
                ranked[j] = current;
            }
        }
    }
    return [result.domain for result in ranked];
}

def validate_coordinator_inputs(
    snapshot: StudentSnapshot,
    academic: AgentResult,
    finance: AgentResult,
    balance: AgentResult
) {
    if academic.domain != Domain.ACADEMIC {
        raise ValueError("academic result has the wrong domain");
    }
    if finance.domain != Domain.FINANCE {
        raise ValueError("finance result has the wrong domain");
    }
    if balance.domain != Domain.BALANCE {
        raise ValueError("balance result has the wrong domain");
    }
    if academic.required_time < 0.0 {
        raise ValueError("academic required time cannot be negative");
    }

    available_hours = snapshot.available_time.available_hours_today;
    for task in snapshot.academic_tasks {
        validate_deadline_inputs(
            task.progress,
            task.estimated_remaining_hours,
            available_hours,
            task.importance
        );
        _ = datetime.fromisoformat(task.deadline);
    }

    finance_facts = assess_finances(snapshot.finance);
    if (
        finance.risk_level != finance_facts.budget_pressure
        or finance.urgency != finance_facts.urgency
    ) {
        raise ValueError("finance result does not match snapshot budget facts");
    }

    balance_facts = assess_balance(academic.required_time, available_hours);
    if (
        balance.risk_level != balance_facts.scheduling_pressure
        or balance.urgency != balance_facts.urgency
        or abs(balance.required_time - balance_facts.maximum_realistic_focused_hours)
            > 0.001
    ) {
        raise ValueError("balance result does not match available-time facts");
    }
}

def select_coordinator_task(
    tasks: list[AcademicTask], required_time: float
) -> AcademicTask | None {
    selected: AcademicTask | None = None;
    for task in tasks {
        if task.progress == 100.0 or task.estimated_remaining_hours == 0.0 {
            continue;
        }
        if abs(task.estimated_remaining_hours - required_time) > 0.001 {
            continue;
        }
        if selected is None {
            selected = task;
            continue;
        }
        selected_task = selected as AcademicTask;
        if datetime.fromisoformat(task.deadline)
            < datetime.fromisoformat(selected_task.deadline) {
            selected = task;
        }
    }
    return selected;
}

def generate_work_blocks(task_title: str, focused_hours: float) -> list[str] {
    blocks: list[str] = [];
    remaining_hours = focused_hours;
    block_number = 1;
    while remaining_hours > 0.001 {
        block_hours = min(COORDINATOR_FOCUS_BLOCK_HOURS, remaining_hours);
        blocks.append(
            f"Focus block {block_number}: {block_hours:.2f} hours on {task_title}"
        );
        remaining_hours -= block_hours;
        block_number += 1;
        if remaining_hours > 0.001 {
            blocks.append(f"Break: {COORDINATOR_BREAK_HOURS:.2f} hours");
        }
    }
    return blocks;
}

def action_for_domain(
    domain: Domain,
    candidate_work_blocks: list[str],
    finance: AgentResult,
    balance: AgentResult
) -> str {
    if domain == Domain.ACADEMIC and len(candidate_work_blocks) > 0 {
        return candidate_work_blocks[0];
    }
    if domain == Domain.FINANCE and finance.recommendation != "" {
        return finance.recommendation;
    }
    if domain == Domain.BALANCE and balance.recommendation != "" {
        return balance.recommendation;
    }
    return "";
}

def build_fallback_deprioritized(
    snapshot: StudentSnapshot,
    selected_task: AcademicTask | None,
    fallback_next_action: str,
    finance_action: str,
    candidate_work_blocks: list[str]
) -> list[str] {
    postponed: list[str] = [];
    for task in snapshot.academic_tasks {
        if task.progress == 100.0 or task.estimated_remaining_hours == 0.0 {
            continue;
        }
        if selected_task is not None and task.id == selected_task.id {
            continue;
        }
        postponed.append(
            f"{task.title} is postponed until after the higher-priority action."
        );
    }
    if fallback_next_action != finance_action and finance_action != "" {
        postponed.append(
            "The Finance action remains active separately instead of replacing the immediate work block."
        );
    }
    if (fallback_next_action == finance_action and len(candidate_work_blocks) > 0) {
        postponed.append("Academic work starts after the immediate Finance action.");
    }
    return postponed;
}

def prepare_coordination(
    snapshot: StudentSnapshot,
    academic: AgentResult,
    finance: AgentResult,
    balance: AgentResult
) -> CoordinatorPreparation {
    validate_coordinator_inputs(snapshot, academic, finance, balance);
    ranked_domains = rank_specialists(academic, finance, balance);
    balance_facts = assess_balance(
        academic.required_time, snapshot.available_time.available_hours_today
    );
    selected_task = select_coordinator_task(
        snapshot.academic_tasks, academic.required_time
    );

    candidate_work_blocks: list[str] = [];
    if selected_task is not None {
        feasible_focused_hours = min(
            academic.required_time, balance_facts.maximum_realistic_focused_hours
        );
        candidate_work_blocks = generate_work_blocks(
            selected_task.title, feasible_focused_hours
        );
    } elif academic.required_time > 0.0 {
        raise ValueError("academic result does not match an unfinished snapshot task");
    }

    conflicts: list[str] = [];
    if not balance_facts.fits_available_time {
        conflicts.append(
            f"Academic requires {academic.required_time:.2f} focused hours, but Balance permits {balance_facts.maximum_realistic_focused_hours:.2f}; resolved by capping and splitting the work."
        );
    }
    if (
        coordinator_level_rank(academic.urgency) >= 3
        and coordinator_level_rank(finance.urgency) >= 3
    ) {
        conflicts.append(
            "Academic and Finance are both urgent; resolved by scheduling feasible study blocks while preserving the Finance action separately."
        );
    }

    candidate_actions: list[str] = [];
    if len(candidate_work_blocks) > 0 {
        candidate_actions.append(candidate_work_blocks[0]);
    }
    if finance.recommendation != "" {
        candidate_actions.append(finance.recommendation);
    }
    if balance.recommendation != "" {
        candidate_actions.append(balance.recommendation);
    }

    fallback_next_action = "Review the current priorities.";
    for domain in ranked_domains {
        candidate = action_for_domain(domain, candidate_work_blocks, finance, balance);
        if candidate != "" {
            fallback_next_action = candidate;
            break;
        }
    }
    if fallback_next_action not in candidate_actions {
        candidate_actions.append(fallback_next_action);
    }

    fallback_deprioritized = build_fallback_deprioritized(
        snapshot,
        selected_task,
        fallback_next_action,
        finance.recommendation,
        candidate_work_blocks
    );
    return CoordinatorPreparation(
        ranked_domains=ranked_domains,
        candidate_actions=candidate_actions,
        candidate_work_blocks=candidate_work_blocks,
        conflicts=conflicts,
        finance_action=finance.recommendation,
        fallback_next_action=fallback_next_action,
        fallback_daily_plan=candidate_work_blocks.copy(),
        fallback_explanation=f"Selected the highest-risk feasible {ranked_domains[
            0
        ]} action after enforcing time and budget constraints.",
        fallback_deprioritized=fallback_deprioritized
    );
}

def strings_are_allowed(values: list[str], allowed: list[str]) -> bool {
    for value in values {
        if value not in allowed {
            return False;
        }
    }
    return True;
}

def plan_is_safe_prefix(plan: list[str], allowed_plan: list[str]) -> bool {
    if len(plan) > len(allowed_plan) {
        return False;
    }
    for index in range(len(plan)) {
        if plan[index] != allowed_plan[index] {
            return False;
        }
    }
    if len(plan) > 0 and plan[-1].startswith("Break:") {
        return False;
    }
    return True;
}

def coordinator_narrative_is_safe(
    narrative: CoordinatorNarrative, preparation: CoordinatorPreparation
) -> bool {
    return (
        narrative.next_action in preparation.candidate_actions
        and plan_is_safe_prefix(narrative.daily_plan, preparation.candidate_work_blocks)
        and strings_are_allowed(
            narrative.deprioritized, preparation.fallback_deprioritized
        )
        and narrative.explanation.strip() != ""
    );
}

sem generate_coordinator_narrative = """
Resolve only soft conflicts in the supplied deterministic preparation. Select
one exact candidate action, create a practical plan using only the provided
work blocks in their existing order, explain why the action won, and select
applicable postponement explanations from the supplied fallback list. Never
change calculated urgency, risk, available-time limits, budget facts, work
block durations, conflicts, or the separate Finance action.
""";

def generate_coordinator_narrative(
    preparation: CoordinatorPreparation
) -> CoordinatorNarrative by llm(temperature=0.0, max_output_retries=1);

def fallback_coordinator_narrative(
    preparation: CoordinatorPreparation
) -> CoordinatorNarrative {
    return CoordinatorNarrative(
        next_action=preparation.fallback_next_action,
        daily_plan=preparation.fallback_daily_plan.copy(),
        explanation=preparation.fallback_explanation,
        deprioritized=preparation.fallback_deprioritized.copy()
    );
}

def build_coordinator_result(
    preparation: CoordinatorPreparation, narrative: CoordinatorNarrative
) -> CoordinatorResult {
    return CoordinatorResult(
        next_action=narrative.next_action,
        daily_plan=narrative.daily_plan,
        finance_action=preparation.finance_action,
        explanation=narrative.explanation,
        conflicts=preparation.conflicts,
        deprioritized=narrative.deprioritized
    );
}

def run_coordinator(
    snapshot: StudentSnapshot,
    academic: AgentResult,
    finance: AgentResult,
    balance: AgentResult,
    narrative_generator:
        Callable[
            [CoordinatorPreparation],
            CoordinatorNarrative
        ] = generate_coordinator_narrative
) -> CoordinatorResult {
    preparation = prepare_coordination(snapshot, academic, finance, balance);
    narrative = fallback_coordinator_narrative(preparation);
    try {
        generated = narrative_generator(preparation);
        if coordinator_narrative_is_safe(generated, preparation) {
            narrative = generated;
        }
    } except (
        AuthenticationError,
        RateLimitError,
        ModelNotFoundError,
        ConfigurationError,
        OutputConversionError,
        FinishToolError
    ) {}
    return build_coordinator_result(preparation, narrative);
}
