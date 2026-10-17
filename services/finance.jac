"""Finance operations backed by Lifora's persistent student graph."""

import from datetime { date }
import from .state {
    Budget,
    DEMO_STUDENT_ID,
    ExpenseRecordResult,
    FinanceView,
    HasExpense,
    find_budget,
    find_expense,
    find_student,
    initialize_expense,
    normalize_expense_date,
    validate_expense_values
}


def build_finance_view(budget: Budget) -> FinanceView {
    spent_today = 0.0;
    today = date.today().isoformat();
    for expense in [budget ->:HasExpense:->] {
        if expense.spent_on == today {
            spent_today += expense.amount;
        }
    }
    return FinanceView(
        weekly_budget=budget.weekly_budget,
        remaining_budget=budget.remaining_budget,
        spent_today=spent_today,
        days_remaining=budget.days_remaining
    );
}


def get_student_finance(student_id: str) -> FinanceView {
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    budget = find_budget(student);
    if budget is None {
        raise ValueError(f"Budget for student '{student_id}' was not found.");
    }
    return build_finance_view(budget);
}


def record_student_expense(
    student_id: str,
    expense_id: str,
    amount: float,
    description: str,
    spent_on: str = ""
) -> ExpenseRecordResult {
    validate_expense_values(expense_id, amount, description);
    expense_date = (
        date.today().isoformat()
        if not spent_on.strip()
        else normalize_expense_date(spent_on)
    );
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    budget = find_budget(student);
    if budget is None {
        raise ValueError(f"Budget for student '{student_id}' was not found.");
    }
    if find_expense(budget, expense_id) is not None {
        raise ValueError(f"Expense '{expense_id}' already exists.");
    }

    created = initialize_expense(
        budget=budget,
        expense_id=expense_id,
        amount=amount,
        description=description,
        spent_on=expense_date
    );
    budget.remaining_budget -= amount;
    return ExpenseRecordResult(
        expense=created.expense.to_view(),
        finance=build_finance_view(budget)
    );
}


def:pub get_finance -> FinanceView {
    return get_student_finance(DEMO_STUDENT_ID);
}


def:pub add_expense(
    expense_id: str,
    amount: float,
    description: str,
    spent_on: str = ""
) -> ExpenseRecordResult {
    return record_student_expense(
        student_id=DEMO_STUDENT_ID,
        expense_id=expense_id,
        amount=amount,
        description=description,
        spent_on=spent_on
    );
}
