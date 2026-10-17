import from datetime { date, timedelta }
import from .state {
    DSA_QUIZ_ID,
    ML_ASSIGNMENT_ID,
    Student,
    initialize_academic_task,
    initialize_demo_academic_tasks,
    initialize_student
}
import from test_support { assert_value_error }


def remove_task_test_student(student_id: str) {
    student = find_student(student_id);
    if student is not None {
        for task in [student->:HasAcademicTask:->] {
            del task;
        }
        del student;
    }
}


def create_task_test_student(student_id: str) -> Student {
    remove_task_test_student(student_id);
    _ = initialize_student(
        student_id=student_id,
        name="Task Test Student",
        life_stage="university",
        available_hours_today=5.0
    );
    student = find_student(student_id);
    if student is None {
        raise RuntimeError("Test student initialization failed.");
    }
    return student;
}


test "academic task initialization is idempotent and preserves progress" {
    student_id = "phase3-idempotency-fixture";
    student = create_task_test_student(student_id);
    deadline = (date.today() + timedelta(days=1)).isoformat();

    first = initialize_academic_task(
        student=student,
        task_id="test-assignment",
        title="Test Assignment",
        deadline=deadline,
        progress=40.0,
        estimated_remaining_hours=3.0,
        importance=5
    );
    assert first.created;
    updated = update_student_task_progress(student_id, "test-assignment", 90.0);
    assert updated.progress == 90.0;

    second = initialize_academic_task(
        student=student,
        task_id="test-assignment",
        title="Replacement Assignment",
        deadline=(date.today() + timedelta(days=5)).isoformat(),
        progress=10.0,
        estimated_remaining_hours=8.0,
        importance=1
    );
    assert not second.created;
    assert second.task.title == "Test Assignment";
    assert second.task.deadline == deadline;
    assert second.task.progress == 90.0;

    tasks = get_student_academic_tasks(student_id);
    assert len(tasks) == 1;
    assert tasks[0].progress == 90.0;
    remove_task_test_student(student_id);
}


test "task progress persists from 40 to 90 percent" {
    student_id = "phase3-progress-fixture";
    student = create_task_test_student(student_id);
    _ = initialize_academic_task(
        student=student,
        task_id="ml-assignment",
        title="Machine Learning Assignment",
        deadline=(date.today() + timedelta(days=1)).isoformat(),
        progress=40.0,
        estimated_remaining_hours=3.0,
        importance=5
    );

    before = get_student_academic_tasks(student_id);
    assert before[0].progress == 40.0;
    _ = update_student_task_progress(student_id, "ml-assignment", 90.0);
    after = get_student_academic_tasks(student_id);
    assert after[0].progress == 90.0;
    remove_task_test_student(student_id);
}


test "task progress rejects values outside 0 to 100" {
    student_id = "phase3-validation-fixture";
    student = create_task_test_student(student_id);
    _ = initialize_academic_task(
        student=student,
        task_id="test-task",
        title="Test Task",
        deadline=date.today().isoformat(),
        progress=40.0,
        estimated_remaining_hours=1.0,
        importance=3
    );

    assert_value_error(
        lambda { update_student_task_progress(student_id, "test-task", -1.0); },
        "between 0 and 100"
    );
    assert_value_error(
        lambda { update_student_task_progress(student_id, "test-task", 101.0); },
        "between 0 and 100"
    );
    assert find_academic_task(student, "test-task")?.progress == 40.0;
    remove_task_test_student(student_id);
}


test "academic task creation validates required fields" {
    student_id = "phase3-fields-fixture";
    student = create_task_test_student(student_id);

    assert_value_error(
        lambda { initialize_academic_task(
            student, "empty-title", "", date.today().isoformat(), 0.0, 1.0, 3
        ); },
        "title is required"
    );
    assert_value_error(
        lambda { initialize_academic_task(
            student,
            "negative-hours",
            "Invalid Task",
            date.today().isoformat(),
            0.0,
            -1.0,
            3
        ); },
        "cannot be negative"
    );
    assert_value_error(
        lambda { initialize_academic_task(
            student, "invalid-date", "Invalid Task", "tomorrow", 0.0, 1.0, 3
        ); },
        "ISO date format"
    );
    assert len(get_student_academic_tasks(student_id)) == 0;
    remove_task_test_student(student_id);
}


test "task operations reject unknown identifiers" {
    student_id = "phase3-missing-fixture";
    _ = create_task_test_student(student_id);
    assert_value_error(
        lambda { update_student_task_progress(student_id, "missing-task", 90.0); },
        "was not found"
    );
    remove_task_test_student(student_id);
}


test "student can add a validated academic task exactly once" {
    student_id = "phase-add-task-fixture";
    _ = create_task_test_student(student_id);
    deadline = (date.today() + timedelta(days=3)).isoformat();

    created = add_student_academic_task(
        student_id,
        "database-exam",
        "Database Systems Exam",
        deadline,
        15.0,
        6.5,
        4
    );
    assert created.id == "database-exam";
    assert created.title == "Database Systems Exam";
    assert created.deadline == deadline;
    assert created.progress == 15.0;
    assert created.estimated_remaining_hours == 6.5;
    assert created.importance == 4;
    assert len(get_student_academic_tasks(student_id)) == 1;

    assert_value_error(
        lambda { add_student_academic_task(
            student_id, "database-exam", "Duplicate", deadline, 0.0, 1.0, 1
        ); },
        "already exists"
    );
    assert len(get_student_academic_tasks(student_id)) == 1;
    remove_task_test_student(student_id);
}


test "task details update atomically and task can be completed" {
    student_id = "phase-edit-task-fixture";
    student = create_task_test_student(student_id);
    original_deadline = date.today().isoformat();
    _ = initialize_academic_task(
        student, "edit-me", "Original", original_deadline, 25.0, 4.0, 2
    );
    new_deadline = (date.today() + timedelta(days=5)).isoformat();
    updated = update_student_academic_task(
        student_id, "edit-me", "Updated title", new_deadline, 50.0, 2.5, 5
    );
    assert updated.title == "Updated title";
    assert updated.deadline == new_deadline;
    assert updated.progress == 50.0;
    assert updated.estimated_remaining_hours == 2.5;
    assert updated.importance == 5;

    assert_value_error(
        lambda { update_student_academic_task(
            student_id, "edit-me", "", new_deadline, 80.0, 1.0, 3
        ); },
        "title is required"
    );
    preserved = find_academic_task(student, "edit-me");
    assert preserved?.title == "Updated title";
    assert preserved?.progress == 50.0;
    completed = update_student_task_progress(student_id, "edit-me", 100.0);
    assert completed.progress == 100.0;
    remove_task_test_student(student_id);
}


test "demo academic seed creates the required tasks once" {
    student_id = "phase3-demo-seed-fixture";
    student = create_task_test_student(student_id);
    initialize_demo_academic_tasks(student);
    initialize_demo_academic_tasks(student);

    tasks = get_student_academic_tasks(student_id);
    assert len(tasks) == 2;
    ml_task = find_academic_task(student, ML_ASSIGNMENT_ID);
    dsa_task = find_academic_task(student, DSA_QUIZ_ID);
    assert ml_task is not None;
    assert dsa_task is not None;
    assert ml_task?.progress == 40.0;
    assert ml_task?.estimated_remaining_hours == 3.0;
    assert ml_task?.deadline == (date.today() + timedelta(days=1)).isoformat();
    assert dsa_task?.deadline == (date.today() + timedelta(days=2)).isoformat();
    remove_task_test_student(student_id);
}
