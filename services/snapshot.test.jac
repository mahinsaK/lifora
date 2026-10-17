import pytest;
import from datetime { date, timedelta }
import from .state {
    HasAcademicTask,
    HasBudget,
    HasExpense,
    Student,
    find_student,
    initialize_academic_task,
    initialize_demo_finance,
    initialize_student,
    update_student_available_time
}
import from .tasks { update_student_task_progress }
import from .finance { record_student_expense }


def remove_snapshot_test_student(student_id: str) {
    student = find_student(student_id);
    if student is not None {
        for task in [student ->:HasAcademicTask:->] {
            del task;
        }
        for budget in [student ->:HasBudget:->] {
            for expense in [budget ->:HasExpense:->] {
                del expense;
            }
            del budget;
        }
        del student;
    }
}


def create_snapshot_test_student(student_id: str) -> Student {
    remove_snapshot_test_student(student_id);
    _ = initialize_student(
        student_id=student_id,
        name="Snapshot Test Student",
        life_stage="university",
        available_hours_today=5.0
    );
    student = find_student(student_id);
    if student is None {
        raise RuntimeError("Test student initialization failed.");
    }
    _ = initialize_academic_task(
        student=student,
        task_id="ml-assignment",
        title="Machine Learning Assignment",
        deadline=(date.today() + timedelta(days=1)).isoformat(),
        progress=40.0,
        estimated_remaining_hours=3.0,
        importance=5
    );
    _ = initialize_academic_task(
        student=student,
        task_id="dsa-quiz",
        title="DSA Quiz",
        deadline=(date.today() + timedelta(days=2)).isoformat(),
        progress=20.0,
        estimated_remaining_hours=2.0,
        importance=4
    );
    initialize_demo_finance(student);
    return student;
}


test "snapshot follows the complete integration contract" {
    student_id = "phase5-contract-fixture";
    _ = create_snapshot_test_student(student_id);
    snapshot = build_student_snapshot(student_id);

    assert snapshot.profile.name == "Snapshot Test Student";
    assert snapshot.profile.life_stage == "university";
    assert len(snapshot.academic_tasks) == 2;
    assert snapshot.academic_tasks[0].id == "ml-assignment";
    assert snapshot.academic_tasks[0].progress == 40.0;
    assert snapshot.finance.weekly_budget == 7000.0;
    assert snapshot.finance.remaining_budget == 3500.0;
    assert snapshot.finance.spent_today == 1500.0;
    assert snapshot.finance.days_remaining == 4;
    assert snapshot.available_time.available_hours_today == 5.0;
    assert snapshot.goals == [];
    remove_snapshot_test_student(student_id);
}


test "snapshot reflects task finance and time mutations" {
    student_id = "phase5-mutations-fixture";
    _ = create_snapshot_test_student(student_id);
    _ = update_student_task_progress(student_id, "ml-assignment", 90.0);
    _ = record_student_expense(
        student_id, "snapshot-expense", 1000.0, "Course materials"
    );
    _ = update_student_available_time(student_id, 2.0);

    snapshot = build_student_snapshot(student_id);
    ml_tasks = [
        task for task in snapshot.academic_tasks
        if task.id == "ml-assignment"
    ];
    assert len(ml_tasks) == 1;
    assert ml_tasks[0].progress == 90.0;
    assert snapshot.finance.remaining_budget == 2500.0;
    assert snapshot.finance.spent_today == 2500.0;
    assert snapshot.available_time.available_hours_today == 2.0;

    repeated = build_student_snapshot(student_id);
    assert repeated.finance.remaining_budget == 2500.0;
    assert repeated.finance.spent_today == 2500.0;
    remove_snapshot_test_student(student_id);
}


test "snapshot reports missing and incomplete state clearly" {
    missing_id = "phase5-missing-fixture";
    remove_snapshot_test_student(missing_id);
    with pytest.raises(ValueError, `match="Student.*was not found") {
        build_student_snapshot(missing_id);
    }

    incomplete_id = "phase5-incomplete-fixture";
    _ = initialize_student(
        incomplete_id,
        "Incomplete Student",
        "university",
        5.0
    );
    with pytest.raises(ValueError, `match="Budget.*was not found") {
        build_student_snapshot(incomplete_id);
    }
    remove_snapshot_test_student(incomplete_id);
}
