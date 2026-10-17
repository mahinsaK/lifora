import from datetime { date, timedelta }
import from test_support { assert_value_error }


test "assignment estimate scales its baseline by remaining progress" {
    deadline = (date.today() + timedelta(days=3)).isoformat();
    estimate = build_task_estimate(
        "Machine Learning Assignment", deadline, 40.0, 5
    );
    assert estimate.estimated_remaining_hours == 3.0;
    assert estimate.confidence == "medium";
    assert "40% progress" in estimate.reason;
}


test "known task types and completed work have predictable estimates" {
    deadline = (date.today() + timedelta(days=7)).isoformat();
    exam = build_task_estimate("Database Final Exam", deadline, 0.0, 4);
    completed = build_task_estimate("Database Final Exam", deadline, 100.0, 4);
    unknown = build_task_estimate("Meet study group", deadline, 0.0, 3);
    assert exam.estimated_remaining_hours == 8.0;
    assert completed.estimated_remaining_hours == 0.0;
    assert unknown.estimated_remaining_hours == 3.0;
    assert unknown.confidence == "low";
}


test "task estimation validates all required inputs" {
    deadline = date.today().isoformat();
    assert_value_error(
        lambda { build_task_estimate("", deadline, 0.0, 3); },
        "title is required"
    );
    assert_value_error(
        lambda { build_task_estimate("Quiz", "tomorrow", 0.0, 3); },
        "ISO date format"
    );
    assert_value_error(
        lambda { build_task_estimate("Quiz", deadline, 101.0, 3); },
        "between 0 and 100"
    );
    assert_value_error(
        lambda { build_task_estimate("Quiz", deadline, 0.0, 6); },
        "between 1 and 5"
    );
}
