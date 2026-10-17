"""Fast, deterministic remaining-work estimates for new academic tasks."""

import from datetime { date }
import from services.state {
    normalize_deadline,
    validate_task_progress
}


obj TaskEstimateView {
    has estimated_remaining_hours: float;
    has confidence: str;
    has reason: str;
}


def task_type_baseline(text: str) -> tuple[float, str] {
    normalized = text.lower();
    if "project" in normalized or "dissertation" in normalized {
        return (10.0, "project");
    }
    if "exam" in normalized or "midterm" in normalized or "final" in normalized {
        return (8.0, "exam preparation");
    }
    if "report" in normalized or "essay" in normalized {
        return (6.0, "written report");
    }
    if "assignment" in normalized or "coursework" in normalized {
        return (5.0, "assignment");
    }
    if "presentation" in normalized or "slides" in normalized {
        return (4.0, "presentation");
    }
    if "quiz" in normalized or "test" in normalized {
        return (2.0, "quiz preparation");
    }
    if "reading" in normalized or "review" in normalized {
        return (2.0, "reading or review");
    }
    return (3.0, "general academic task");
}


def build_task_estimate(
    title: str,
    deadline: str,
    progress: float,
    importance: int,
    description: str = ""
) -> TaskEstimateView {
    if not title.strip() {
        raise ValueError("Task title is required for an estimate.");
    }
    normalized_deadline = normalize_deadline(deadline);
    validate_task_progress(progress);
    if importance < 1 or importance > 5 {
        raise ValueError("Task importance must be between 1 and 5.");
    }

    estimate_profile: tuple[float, str] = task_type_baseline(title + " " + description);
    baseline: float = estimate_profile[0];
    task_type: str = estimate_profile[1];
    remaining_ratio: float = (100.0 - progress) / 100.0;
    raw_hours: float = baseline * remaining_ratio;
    half_hours: int = int(raw_hours * 2.0 + 0.5);
    rounded_hours: float = float(half_hours) / 2.0;
    estimated_hours: float = 0.0;
    if progress < 100.0 {
        estimated_hours = rounded_hours if rounded_hours >= 0.5 else 0.5;
    }
    days_until = (date.fromisoformat(normalized_deadline) - date.today()).days;
    timing = (
        "overdue"
        if days_until < 0
        else ("due today" if days_until == 0 else f"due in {days_until} days")
    );
    known_type = task_type != "general academic task";
    confidence = "medium" if known_type else "low";
    reason = (
        f"Estimated from the {task_type} baseline, {int(round(progress))}% progress, "
        + f"importance {importance}/5, and a deadline {timing}."
    );
    return TaskEstimateView(
        estimated_remaining_hours=estimated_hours,
        confidence=confidence,
        reason=reason
    );
}


def:pub estimate_task_hours(
    title: str,
    deadline: str,
    progress: float,
    importance: int,
    description: str = ""
) -> TaskEstimateView {
    return build_task_estimate(title, deadline, progress, importance, description);
}
