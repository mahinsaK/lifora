import from datetime { date, timedelta }
import from .state {
    DEMO_DAYS_REMAINING,
    DEMO_PRIOR_EXPENSE_ID,
    DEMO_REMAINING_BUDGET,
    DEMO_TODAY_EXPENSE_ID,
    DEMO_WEEKLY_BUDGET,
    HasBudget,
    HasReversal,
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
            for income in [budget->:HasIncome:->] {
                del income;
            }
            for reversal in [budget->:HasReversal:->] {
                del reversal;
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


test "income increases available funds without changing recorded spending" {
    student_id = "phase-income-fixture";
    student = create_finance_test_student(student_id);
    initialize_demo_finance(student);

    result = record_student_income(
        student_id, "allowance-1", 2000.0, "Monthly allowance", date.today().isoformat()
    );
    assert result.income.id == "allowance-1";
    assert result.income.amount == 2000.0;
    assert result.finance.weekly_budget == 9000.0;
    assert result.finance.remaining_budget == 5500.0;
    assert result.finance.spent_today == 1500.0;

    assert_value_error(
        lambda { record_student_income(student_id, "allowance-1", 2000.0, "Again"); },
        "already exists"
    );
    assert get_student_finance(student_id).remaining_budget == 5500.0;
    remove_finance_test_student(student_id);
}


test "income validates amount description and date" {
    student_id = "phase-income-validation-fixture";
    student = create_finance_test_student(student_id);
    _ = initialize_budget(student, 7000.0, 3500.0, 4);
    assert_value_error(
        lambda { record_student_income(student_id, "bad-amount", 0.0, "Allowance"); },
        "greater than zero"
    );
    assert_value_error(
        lambda { record_student_income(student_id, "bad-description", 10.0, ""); },
        "description is required"
    );
    assert_value_error(
        lambda { record_student_income(student_id, "bad-date", 10.0, "Allowance", "today"); },
        "ISO date format"
    );
    remove_finance_test_student(student_id);
}


test "transaction history combines income and expenses newest first" {
    student_id = "phase-history-fixture";
    student = create_finance_test_student(student_id);
    _ = initialize_budget(student, 7000.0, 7000.0, 4);
    _ = record_student_expense(student_id, "older-expense", 500.0, "Bus", "2026-10-15");
    _ = record_student_income(student_id, "newer-income", 1000.0, "Allowance", "2026-10-16");

    history = get_student_transactions(student_id);
    assert len(history) == 2;
    assert history[0].id == "newer-income";
    assert history[0].kind == "INCOME";
    assert history[1].id == "older-expense";
    assert history[1].kind == "EXPENSE";
    remove_finance_test_student(student_id);
}


test "reversing an expense restores funds and preserves an audit entry" {
    student_id = "phase-reverse-expense-fixture";
    student = create_finance_test_student(student_id);
    _ = initialize_budget(student, 7000.0, 7000.0, 4);
    _ = record_student_expense(
        student_id, "wrong-expense", 500.0, "Entered by mistake", date.today().isoformat()
    );

    result = reverse_student_transaction(student_id, "wrong-expense", "EXPENSE");
    assert result.finance.remaining_budget == 7000.0;
    assert result.finance.spent_today == 0.0;
    assert result.transaction.reversed;
    assert result.transaction.reversed_on == date.today().isoformat();

    history = get_student_transactions(student_id);
    assert len(history) == 1;
    assert history[0].id == "wrong-expense";
    assert history[0].reversed;
    assert_value_error(
        lambda { reverse_student_transaction(student_id, "wrong-expense", "EXPENSE"); },
        "already reversed"
    );
    assert get_student_finance(student_id).remaining_budget == 7000.0;
    remove_finance_test_student(student_id);
}


test "income reversal removes only unspent funds" {
    student_id = "phase-reverse-income-fixture";
    student = create_finance_test_student(student_id);
    _ = initialize_budget(student, 7000.0, 3500.0, 4);
    _ = record_student_income(student_id, "wrong-income", 1000.0, "Wrong amount");

    result = reverse_student_transaction(student_id, "wrong-income", "income");
    assert result.finance.weekly_budget == 7000.0;
    assert result.finance.remaining_budget == 3500.0;
    assert result.transaction.reversed;

    _ = record_student_income(student_id, "spent-income", 2000.0, "Already used");
    _ = record_student_expense(student_id, "large-expense", 4000.0, "Rent");
    assert_value_error(
        lambda { reverse_student_transaction(student_id, "spent-income", "INCOME"); },
        "already been spent"
    );
    assert get_student_finance(student_id).remaining_budget == 1500.0;
    remove_finance_test_student(student_id);
}


test "transaction reversal validates identifiers and kind" {
    student_id = "phase-reverse-validation-fixture";
    student = create_finance_test_student(student_id);
    _ = initialize_budget(student, 7000.0, 3500.0, 4);
    assert_value_error(
        lambda { reverse_student_transaction(student_id, "", "EXPENSE"); },
        "ID is required"
    );
    assert_value_error(
        lambda { reverse_student_transaction(student_id, "missing", "TRANSFER"); },
        "EXPENSE or INCOME"
    );
    assert_value_error(
        lambda { reverse_student_transaction(student_id, "missing", "EXPENSE"); },
        "was not found"
    );
    remove_finance_test_student(student_id);
}
