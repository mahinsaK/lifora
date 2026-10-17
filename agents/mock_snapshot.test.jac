test "demo snapshot matches the documented starting scenario" {
    snapshot = build_demo_snapshot();
    ml_assignment = snapshot.academic_tasks[0];
    dsa_quiz = snapshot.academic_tasks[1];

    assert snapshot.profile.life_stage == "university";
    assert len(snapshot.academic_tasks) == 2;
    assert ml_assignment.id == "ml-assignment";
    assert ml_assignment.title == "Machine Learning Assignment";
    assert ml_assignment.progress == 40.0;
    assert ml_assignment.estimated_remaining_hours == 3.0;
    assert dsa_quiz.title == "DSA Quiz";
    assert dsa_quiz.progress == 20.0;
    assert dsa_quiz.estimated_remaining_hours == 2.0;
    assert dsa_quiz.importance == 4;
    assert snapshot.finance.weekly_budget == 7000.0;
    assert snapshot.finance.remaining_budget == 3500.0;
    assert snapshot.finance.spent_today == 1500.0;
    assert snapshot.finance.days_remaining == 4;
    assert snapshot.available_time.available_hours_today == 5.0;
    assert snapshot.goals == [];
}

test "demo snapshot factory returns independent state" {
    first = build_demo_snapshot();
    second = build_demo_snapshot();

    first.academic_tasks[0].progress = 90.0;
    first.goals.append("A temporary test goal");

    assert second.academic_tasks[0].progress == 40.0;
    assert second.goals == [];
}
