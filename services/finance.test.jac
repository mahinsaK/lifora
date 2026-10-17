import from datetime { date, timedelta }
import from .state {
    DEMO_DAYS_REMAINING,
    DEMO_PRIOR_EXPENSE_ID,
    DEMO_REMAINING_BUDGET,
    DEMO_TODAY_EXPENSE_ID,
    DEMO_WEEKLY_BUDGET,
    HasBudget,
    Student,
    find_student,
    initialize_budget,
    initialize_demo_finance,
    initialize_expense,
    initialize_student,
    update_student_available_time
}
import from test_support { assert_value_error }


def remove_finance_test_student(student_id: str) {
    student = find_student(student_id);
    if student is not None {
        for budget in [student->:HasBudget:->] {
            for expense in [budget->:HasExpense:->] {
                del expense;
            }
            del budget;
        }
        del student;
    }
}


def create_finance_test_student(student_id: str) -> Student {
    remove_finance_test_student(student_id);
    _ = initialize_student(
        student_id=student_id,
        name="Finance Test Student",
        life_stage="university",
        available_hours_today=5.0
    );
    student = find_student(student_id);
    if student is None {
        raise RuntimeError("Test student initialization failed.");
    }
    return student;
}


test "demo finance seed is idempotent and preserves mutations" {
    student_id = "phase4-seed-fixture";
    student = create_finance_test_student(student_id);
    initialize_demo_finance(student);
    initialize_demo_finance(student);

    initial = get_student_finance(student_id);
    assert initial.weekly_budget == DEMO_WEEKLY_BUDGET;
    assert initial.remaining_budget == DEMO_REMAINING_BUDGET;
    assert initial.spent_today == 1500.0;
    assert initial.days_remaining == DEMO_DAYS_REMAINING;
    budget = find_budget(student);
    if budget is None {
        raise RuntimeError("Demo budget initialization failed.");
    }
    assert find_expense(budget, DEMO_PRIOR_EXPENSE_ID) is not None;
    assert find_expense(budget, DEMO_TODAY_EXPENSE_ID) is not None;
    assert len([budget->:HasExpense:->]) == 2;

    _ = record_student_expense(
        student_id, "demo-new-expense", 1000.0, "Course materials"
    );
    initialize_demo_finance(student);
    preserved = get_student_finance(student_id);
    assert preserved.remaining_budget == 2500.0;
    assert preserved.spent_today == 2500.0;
    remove_finance_test_student(student_id);
}


test "expense updates budget once and repeated reads are safe" {
    student_id = "phase4-expense-fixture";
    student = create_finance_test_student(student_id);
    initialize_demo_finance(student);

    result = record_student_expense(
        student_id=student_id,
        expense_id="books-1000",
        amount=1000.0,
        description="Books"
    );
    assert result.expense.amount == 1000.0;
    assert result.finance.remaining_budget == 2500.0;
    assert result.finance.spent_today == 2500.0;

    first_read = get_student_finance(student_id);
    second_read = get_student_finance(student_id);
    assert first_read.remaining_budget == 2500.0;
    assert second_read.remaining_budget == 2500.0;
    assert_value_error(
        lambda { record_student_expense(student_id, "books-1000", 1000.0, "Books"); },
        "already exists"
    );
    assert get_student_finance(student_id).remaining_budget == 2500.0;
    remove_finance_test_student(student_id);
}


test "only expenses recorded today affect spent today" {
    student_id = "phase4-date-fixture";
    student = create_finance_test_student(student_id);
    _ = initialize_budget(student, 7000.0, 7000.0, 4);

    yesterday = (date.today() - timedelta(days=1)).isoformat();
    result = record_student_expense(
        student_id, "yesterday-expense", 500.0, "Transport", yesterday
    );
    assert result.finance.remaining_budget == 6500.0;
    assert result.finance.spent_today == 0.0;
    remove_finance_test_student(student_id);
}


test "finance operations reject invalid expenses and missing budgets" {
    student_id = "phase4-validation-fixture";
    student = create_finance_test_student(student_id);
    _ = initialize_budget(student, 7000.0, 3500.0, 4);

    assert_value_error(
        lambda { record_student_expense(student_id, "negative", -1.0, "Invalid"); },
        "greater than zero"
    );
    assert_value_error(
        lambda { record_student_expense(student_id, "empty-description", 10.0, ""); },
        "description is required"
    );
    assert_value_error(
        lambda { record_student_expense(
            student_id, "bad-date", 10.0, "Invalid date", "today"
        ); },
        "ISO date format"
    );
    assert get_student_finance(student_id).remaining_budget == 3500.0;
    remove_finance_test_student(student_id);

    no_budget_id = "phase4-no-budget-fixture";
    _ = create_finance_test_student(no_budget_id);
    assert_value_error(
        lambda { get_student_finance(no_budget_id); }, "Budget.*was not found"
    );
    remove_finance_test_student(no_budget_id);
}


test "available time updates from five to two hours" {
    student_id = "phase4-time-fixture";
    _ = create_finance_test_student(student_id);
    updated = update_student_available_time(student_id, 2.0);
    assert updated.available_time.available_hours_today == 2.0;
    assert find_student(student_id)?.available_hours_today == 2.0;
    remove_finance_test_student(student_id);
}
