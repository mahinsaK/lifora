import pytest;
import from services.state { AcademicTaskView }

glob FIXED_ADAPTER_NOW = "2026-10-17T18:00:00+05:30";

test "timezone-aware deadline passes through unchanged" {
    deadline = "2026-10-19T23:59:00+05:30";

    assert normalize_planning_deadline(deadline, FIXED_ADAPTER_NOW) == deadline;
}

test "date-only deadline adapts to end of day in planning timezone" {
    assert normalize_planning_deadline("2026-10-19", FIXED_ADAPTER_NOW)
        == "2026-10-19T23:59:00+05:30";
}

test "naive datetime is rejected instead of guessing a timezone" {
    with pytest.raises(ValueError, `match="timezone-aware") {
        normalize_planning_deadline("2026-10-19T23:59:00", FIXED_ADAPTER_NOW);
    }
}

test "task adaptation preserves service values without mutation" {
    original = AcademicTaskView(
        id="dsa-quiz",
        title="DSA Quiz",
        deadline="2026-10-19",
        progress=20.0,
        estimated_remaining_hours=2.0,
        importance=4
    );
    adapted = adapt_academic_tasks([original], FIXED_ADAPTER_NOW);

    assert adapted[0].deadline == "2026-10-19T23:59:00+05:30";
    assert adapted[0].progress == 20.0;
    assert adapted[0].estimated_remaining_hours == 2.0;
    assert adapted[0].importance == 4;
    assert original.deadline == "2026-10-19";
}
