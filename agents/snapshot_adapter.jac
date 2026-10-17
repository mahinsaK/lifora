import from datetime { date, datetime }
import from services.state { AcademicTaskView }

def normalize_planning_deadline(deadline: str, current_time: str) -> str {
    current = datetime.fromisoformat(current_time);
    if current.utcoffset() is None {
        raise ValueError("planning current time must include a timezone offset");
    }

    parsed = datetime.fromisoformat(deadline);
    if parsed.utcoffset() is not None {
        return parsed.isoformat();
    }
    if "T" in deadline {
        raise ValueError(
            "task deadline must be a date or a timezone-aware ISO 8601 datetime"
        );
    }

    deadline_date = date.fromisoformat(deadline).isoformat();
    offset = current.strftime("%z");
    formatted_offset = f"{offset[:3]}:{offset[3:]}";
    return f"{deadline_date}T23:59:00{formatted_offset}";
}

def adapt_academic_tasks(
    tasks: list[AcademicTaskView], current_time: str
) -> list[AcademicTaskView] {
    return [
        AcademicTaskView(
            id=task.id,
            title=task.title,
            deadline=normalize_planning_deadline(task.deadline, current_time),
            progress=task.progress,
            estimated_remaining_hours=task.estimated_remaining_hours,
            importance=task.importance
        ) for task in tasks
    ];
}
