def remove_test_student(student_id: str) {
    student = find_student(student_id);
    if student is not None {
        del student;
    }
}


test "student initialization is idempotent and preserves updates" {
    student_id = "phase1-idempotency-fixture";
    remove_test_student(student_id);

    first = initialize_student(
        student_id=student_id,
        name="Test Student",
        life_stage="university",
        available_hours_today=5.0
    );
    assert first.created;
    assert first.state.available_time.available_hours_today == 5.0;

    updated = update_student_available_time(student_id, 2.0);
    assert updated.available_time.available_hours_today == 2.0;

    second = initialize_student(
        student_id=student_id,
        name="Replacement Name",
        life_stage="replacement-stage",
        available_hours_today=12.0
    );
    assert not second.created;
    assert second.state.profile.name == "Test Student";
    assert second.state.profile.life_stage == "university";
    assert second.state.available_time.available_hours_today == 2.0;

    matches = [
        student
        for student in [root -->[?:Student]]
        if student.student_id == student_id
    ];
    assert len(matches) == 1;
    remove_test_student(student_id);
}


test "available time rejects values outside one day" {
    student_id = "phase1-validation-fixture";
    remove_test_student(student_id);
    _ = initialize_student(
        student_id=student_id,
        name="Test Student",
        life_stage="university",
        available_hours_today=5.0
    );

    with testraises(ValueError, `match="between 0 and 24") {
        update_student_available_time(student_id, -1.0);
    }
    with testraises(ValueError, `match="between 0 and 24") {
        update_student_available_time(student_id, 25.0);
    }
    assert find_student(student_id)?.available_hours_today == 5.0;
    remove_test_student(student_id);
}


test "available time update requires an existing student" {
    student_id = "phase1-missing-fixture";
    remove_test_student(student_id);
    with testraises(ValueError, `match="was not found") {
        update_student_available_time(student_id, 2.0);
    }
}
