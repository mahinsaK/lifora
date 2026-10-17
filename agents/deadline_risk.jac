import from datetime { datetime }
import from agents.types { RiskLevel }

def validate_deadline_inputs(
    progress: float,
    estimated_remaining_hours: float,
    available_hours: float,
    importance: int
) {
    if progress < 0.0 or progress > 100.0 {
        raise ValueError("progress must be between 0 and 100");
    }
    if estimated_remaining_hours < 0.0 {
        raise ValueError("estimated remaining hours cannot be negative");
    }
    if available_hours < 0.0 {
        raise ValueError("available hours cannot be negative");
    }
    if importance < 1 or importance > 5 {
        raise ValueError("importance must be between 1 and 5");
    }
}

def hours_before_deadline(current_time: str, deadline: str) -> float {
    current = datetime.fromisoformat(current_time);
    due = datetime.fromisoformat(deadline);

    if (current.utcoffset() is None) != (due.utcoffset() is None) {
        raise ValueError("current time and deadline must use compatible time zones");
    }

    return (due - current).total_seconds() / 3600.0;
}

"""Classify deadline risk using explainable capacity thresholds."""
def assess_deadline_risk(
    current_time: str,
    deadline: str,
    progress: float,
    estimated_remaining_hours: float,
    available_hours: float,
    importance: int
) -> RiskLevel {
    validate_deadline_inputs(
        progress, estimated_remaining_hours, available_hours, importance
    );
    hours_remaining = hours_before_deadline(current_time, deadline);

    if progress == 100.0 or estimated_remaining_hours == 0.0 {
        return RiskLevel.LOW;
    }

    if hours_remaining <= 0.0 {
        return RiskLevel.CRITICAL;
    }

    usable_hours = min(available_hours, hours_remaining);
    if estimated_remaining_hours > usable_hours {
        return RiskLevel.CRITICAL;
    }

    capacity_used = estimated_remaining_hours / usable_hours;
    if capacity_used >= 0.8 {
        return RiskLevel.HIGH;
    }
    if capacity_used >= 0.5 {
        if importance >= 4 {
            return RiskLevel.HIGH;
        }
        return RiskLevel.MEDIUM;
    }
    if importance == 5 and hours_remaining <= 24.0 {
        return RiskLevel.MEDIUM;
    }
    return RiskLevel.LOW;
}
