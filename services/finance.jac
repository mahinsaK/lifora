"""Finance operations backed by Lifora's persistent student graph."""

import from datetime { date }
import from services.state {
    Budget,
    DEMO_STUDENT_ID,
    ExpenseRecordResult,
    FinanceView,
    HasIncome,
    Income,
    IncomeRecordResult,
    TransactionReversalResult,
    TransactionReversal,
    TransactionView,
    HasExpense,
    find_budget,
    find_expense,
    find_income,
    find_reversal,
    find_student,
    initialize_expense,
    normalize_expense_date,
    validate_expense_values
    ,validate_income_values
}


def build_finance_view(budget: Budget) -> FinanceView {
    spent_today = 0.0;
    today = date.today().isoformat();
    for expense in [budget ->:HasExpense:->] {
        if expense.spent_on == today and find_reversal(budget, expense.expense_id, "EXPENSE") is None {
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


def get_student_transactions(student_id: str) -> list[TransactionView] {
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    budget = find_budget(student);
    if budget is None {
        raise ValueError(f"Budget for student '{student_id}' was not found.");
    }
    transactions: list[TransactionView] = [];
    for expense in [budget ->:HasExpense:->] {
        reversal = find_reversal(budget, expense.expense_id, "EXPENSE");
        transactions.append(TransactionView(
            id=expense.expense_id,
            kind="EXPENSE",
            amount=expense.amount,
            description=expense.description,
            occurred_on=expense.spent_on,
            reversed=reversal is not None,
            reversed_on=reversal.reversed_on if reversal else ""
        ));
    }
    for income in [budget ->:HasIncome:->] {
        reversal = find_reversal(budget, income.income_id, "INCOME");
        transactions.append(TransactionView(
            id=income.income_id,
            kind="INCOME",
            amount=income.amount,
            description=income.description,
            occurred_on=income.received_on,
            reversed=reversal is not None,
            reversed_on=reversal.reversed_on if reversal else ""
        ));
    }
    return sorted(
        transactions,
        key=lambda (item: TransactionView) { item.occurred_on + item.id; },
        reverse=True
    );
}


def reverse_student_transaction(
    student_id: str,
    transaction_id: str,
    kind: str
) -> TransactionReversalResult {
    if not transaction_id.strip() {
        raise ValueError("Transaction ID is required.");
    }
    normalized_kind = kind.strip().upper();
    if normalized_kind not in ["EXPENSE", "INCOME"] {
        raise ValueError("Transaction kind must be EXPENSE or INCOME.");
    }
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    budget = find_budget(student);
    if budget is None {
        raise ValueError(f"Budget for student '{student_id}' was not found.");
    }
    reversed_on = date.today().isoformat();
    if normalized_kind == "EXPENSE" {
        expense = find_expense(budget, transaction_id);
        if expense is None {
            raise ValueError(f"Expense '{transaction_id}' was not found.");
        }
        if find_reversal(budget, transaction_id, normalized_kind) is not None {
            raise ValueError(f"Expense '{transaction_id}' is already reversed.");
        }
        _ = budget +>:HasReversal():+> TransactionReversal(
            transaction_id=transaction_id,
            kind=normalized_kind,
            reversed_on=reversed_on
        );
        budget.remaining_budget += expense.amount;
        transaction = TransactionView(
            id=expense.expense_id,
            kind="EXPENSE",
            amount=expense.amount,
            description=expense.description,
            occurred_on=expense.spent_on,
            reversed=True,
            reversed_on=reversed_on
        );
    } else {
        income = find_income(budget, transaction_id);
        if income is None {
            raise ValueError(f"Income '{transaction_id}' was not found.");
        }
        if find_reversal(budget, transaction_id, normalized_kind) is not None {
            raise ValueError(f"Income '{transaction_id}' is already reversed.");
        }
        if budget.remaining_budget < income.amount {
            raise ValueError("This income cannot be reversed because some of those funds have already been spent.");
        }
        _ = budget +>:HasReversal():+> TransactionReversal(
            transaction_id=transaction_id,
            kind=normalized_kind,
            reversed_on=reversed_on
        );
        budget.weekly_budget -= income.amount;
        budget.remaining_budget -= income.amount;
        transaction = TransactionView(
            id=income.income_id,
            kind="INCOME",
            amount=income.amount,
            description=income.description,
            occurred_on=income.received_on,
            reversed=True,
            reversed_on=reversed_on
        );
    }
    return TransactionReversalResult(
        transaction=transaction,
        finance=build_finance_view(budget)
    );
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


def record_student_income(
    student_id: str,
    transaction_id: str,
    amount: float,
    description: str,
    received_on: str = ""
) -> IncomeRecordResult {
    validate_income_values(transaction_id, amount, description);
    income_date = (
        date.today().isoformat()
        if not received_on.strip()
        else normalize_expense_date(received_on)
    );
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    budget = find_budget(student);
    if budget is None {
        raise ValueError(f"Budget for student '{student_id}' was not found.");
    }
    if find_income(budget, transaction_id) is not None {
        raise ValueError(f"Income '{transaction_id}' already exists.");
    }

    income = budget +>:HasIncome():+> Income(
        income_id=transaction_id,
        amount=amount,
        description=description.strip(),
        received_on=income_date
    );
    budget.weekly_budget += amount;
    budget.remaining_budget += amount;
    return IncomeRecordResult(
        income=income.to_view(),
        finance=build_finance_view(budget)
    );
}


def:pub get_finance -> FinanceView {
    return get_student_finance(DEMO_STUDENT_ID);
}


def:pub get_transactions -> list[TransactionView] {
    return get_student_transactions(DEMO_STUDENT_ID);
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


def:pub add_income(
    transaction_id: str,
    amount: float,
    description: str,
    received_on: str = ""
) -> IncomeRecordResult {
    return record_student_income(
        student_id=DEMO_STUDENT_ID,
        transaction_id=transaction_id,
        amount=amount,
        description=description,
        received_on=received_on
    );
}


def:pub reverse_transaction(
    transaction_id: str,
    kind: str
) -> TransactionReversalResult {
    return reverse_student_transaction(
        student_id=DEMO_STUDENT_ID,
        transaction_id=transaction_id,
        kind=kind
    );
}
