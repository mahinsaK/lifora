"""Persistent student profile, availability, and academic state for Lifora."""

import from datetime { date, timedelta }

glob DEMO_STUDENT_ID: str = "demo-student";
glob DEMO_STUDENT_NAME: str = "Demo Student";
glob UNIVERSITY_LIFE_STAGE: str = "university";
glob DEMO_AVAILABLE_HOURS: float = 5.0;
glob ML_ASSIGNMENT_ID: str = "ml-assignment";
glob ML_ASSIGNMENT_TITLE: str = "Machine Learning Assignment";
glob DSA_QUIZ_ID: str = "dsa-quiz";
glob DSA_QUIZ_TITLE: str = "DSA Quiz";
glob DEMO_WEEKLY_BUDGET: float = 7000.0;
glob DEMO_REMAINING_BUDGET: float = 3500.0;
glob DEMO_DAYS_REMAINING: int = 4;
glob DEMO_PRIOR_EXPENSE_ID: str = "demo-prior-expense";
glob DEMO_TODAY_EXPENSE_ID: str = "demo-today-expense";


obj ProfileView {
    has name: str;
    has life_stage: str;
}


obj AvailableTimeView {
    has available_hours_today: float;
}


obj StudentStateView {
    has profile: ProfileView;
    has available_time: AvailableTimeView;
}


obj StateInitializationResult {
    has state: StudentStateView;
    has created: bool;
}


obj AcademicTaskView {
    has id: str;
    has title: str;
    has deadline: str;
    has progress: float;
    has estimated_remaining_hours: float;
    has importance: int;
}


obj TaskInitializationResult {
    has task: AcademicTaskView;
    has created: bool;
}


obj FinanceView {
    has weekly_budget: float;
    has remaining_budget: float;
    has spent_today: float;
    has days_remaining: int;
}


obj ExpenseView {
    has id: str;
    has amount: float;
    has description: str;
    has spent_on: str;
}


obj ExpenseRecordResult {
    has expense: ExpenseView;
    has finance: FinanceView;
}


obj IncomeView {
    has id: str;
    has amount: float;
    has description: str;
    has received_on: str;
}


obj IncomeRecordResult {
    has income: IncomeView;
    has finance: FinanceView;
}


obj BudgetInitializationResult {
    has budget: Budget;
    has created: bool;
}


obj ExpenseInitializationResult {
    has expense: Expense;
    has created: bool;
}


node Student {
    has student_id: str;
    has name: str;
    has life_stage: str;
    has available_hours_today: float;

    def to_view -> StudentStateView {
        return StudentStateView(
            profile=ProfileView(
                name=self.name,
                life_stage=self.life_stage
            ),
            available_time=AvailableTimeView(
                available_hours_today=self.available_hours_today
            )
        );
    }
}


node AcademicTask {
    has task_id: str;
    has title: str;
    has deadline: str;
    has progress: float;
    has estimated_remaining_hours: float;
    has importance: int;

    def to_view -> AcademicTaskView {
        return AcademicTaskView(
            id=self.task_id,
            title=self.title,
            deadline=self.deadline,
            progress=self.progress,
            estimated_remaining_hours=self.estimated_remaining_hours,
            importance=self.importance
        );
    }
}


node Budget {
    has weekly_budget: float;
    has remaining_budget: float;
    has days_remaining: int;
}


node Expense {
    has expense_id: str;
    has amount: float;
    has description: str;
    has spent_on: str;

    def to_view -> ExpenseView {
        return ExpenseView(
            id=self.expense_id,
            amount=self.amount,
            description=self.description,
            spent_on=self.spent_on
        );
    }
}


node Income {
    has income_id: str;
    has amount: float;
    has description: str;
    has received_on: str;

    def to_view -> IncomeView {
        return IncomeView(
            id=self.income_id,
            amount=self.amount,
            description=self.description,
            received_on=self.received_on
        );
    }
}


edge HasAcademicTask: Student --> AcademicTask {}
edge HasBudget: Student --> Budget {}
edge HasExpense: Budget --> Expense {}
edge HasIncome: Budget --> Income {}


def validate_available_hours(available_hours_today: float) {
    if available_hours_today < 0.0 or available_hours_today > 24.0 {
        raise ValueError("Available hours today must be between 0 and 24.");
    }
}


def validate_task_progress(progress: float) {
    if progress < 0.0 or progress > 100.0 {
        raise ValueError("Task progress must be between 0 and 100.");
    }
}


def normalize_deadline(deadline: str) -> str {
    try {
        return date.fromisoformat(deadline).isoformat();
    } except ValueError {
        raise ValueError("Task deadline must use ISO date format YYYY-MM-DD.");
    }
}


def validate_budget_values(
    weekly_budget: float,
    remaining_budget: float,
    days_remaining: int
) {
    if weekly_budget < 0.0 {
        raise ValueError("Weekly budget cannot be negative.");
    }
    if remaining_budget < 0.0 or remaining_budget > weekly_budget {
        raise ValueError(
            "Remaining budget must be between 0 and the weekly budget."
        );
    }
    if days_remaining < 0 or days_remaining > 7 {
        raise ValueError("Days remaining must be between 0 and 7.");
    }
}


def validate_expense_values(
    expense_id: str,
    amount: float,
    description: str
) {
    if not expense_id.strip() {
        raise ValueError("Expense ID is required.");
    }
    if amount <= 0.0 {
        raise ValueError("Expense amount must be greater than zero.");
    }
    if not description.strip() {
        raise ValueError("Expense description is required.");
    }
}


def validate_income_values(
    income_id: str,
    amount: float,
    description: str
) {
    if not income_id.strip() {
        raise ValueError("Income ID is required.");
    }
    if amount <= 0.0 {
        raise ValueError("Income amount must be greater than zero.");
    }
    if not description.strip() {
        raise ValueError("Income description is required.");
    }
}


def normalize_expense_date(spent_on: str) -> str {
    try {
        return date.fromisoformat(spent_on).isoformat();
    } except ValueError {
        raise ValueError("Expense date must use ISO date format YYYY-MM-DD.");
    }
}


def find_student(student_id: str) -> Student | None {
    for student in [root -->[?:Student]] {
        if student.student_id == student_id {
            return student;
        }
    }
    return None;
}


def find_academic_task(
    student: Student,
    task_id: str
) -> AcademicTask | None {
    for task in [student ->:HasAcademicTask:->] {
        if task.task_id == task_id {
            return task;
        }
    }
    return None;
}


def find_budget(student: Student) -> Budget | None {
    budgets = [student ->:HasBudget:->];
    return budgets[0] if budgets else None;
}


def find_expense(budget: Budget, expense_id: str) -> Expense | None {
    for expense in [budget ->:HasExpense:->] {
        if expense.expense_id == expense_id {
            return expense;
        }
    }
    return None;
}


def find_income(budget: Budget, income_id: str) -> Income | None {
    for income in [budget ->:HasIncome:->] {
        if income.income_id == income_id {
            return income;
        }
    }
    return None;
}


def initialize_student(
    student_id: str,
    name: str,
    life_stage: str,
    available_hours_today: float
) -> StateInitializationResult {
    if not student_id.strip() {
        raise ValueError("Student ID is required.");
    }
    if not name.strip() {
        raise ValueError("Student name is required.");
    }
    if not life_stage.strip() {
        raise ValueError("Life stage is required.");
    }
    validate_available_hours(available_hours_today);

    existing = find_student(student_id);
    if existing is not None {
        return StateInitializationResult(
            state=existing.to_view(),
            created=False
        );
    }

    student = root ++> Student(
        student_id=student_id,
        name=name,
        life_stage=life_stage,
        available_hours_today=available_hours_today
    );
    return StateInitializationResult(
        state=student.to_view(),
        created=True
    );
}


def initialize_academic_task(
    student: Student,
    task_id: str,
    title: str,
    deadline: str,
    progress: float,
    estimated_remaining_hours: float,
    importance: int
) -> TaskInitializationResult {
    if not task_id.strip() {
        raise ValueError("Task ID is required.");
    }
    if not title.strip() {
        raise ValueError("Task title is required.");
    }
    normalized_deadline = normalize_deadline(deadline);
    validate_task_progress(progress);
    if estimated_remaining_hours < 0.0 {
        raise ValueError("Estimated remaining hours cannot be negative.");
    }
    if importance < 1 or importance > 5 {
        raise ValueError("Task importance must be between 1 and 5.");
    }

    existing = find_academic_task(student, task_id);
    if existing is not None {
        return TaskInitializationResult(
            task=existing.to_view(),
            created=False
        );
    }

    task = student +>:HasAcademicTask():+> AcademicTask(
        task_id=task_id,
        title=title,
        deadline=normalized_deadline,
        progress=progress,
        estimated_remaining_hours=estimated_remaining_hours,
        importance=importance
    );
    return TaskInitializationResult(task=task.to_view(), created=True);
}


def initialize_demo_academic_tasks(student: Student) {
    today = date.today();
    _ = initialize_academic_task(
        student=student,
        task_id=ML_ASSIGNMENT_ID,
        title=ML_ASSIGNMENT_TITLE,
        deadline=(today + timedelta(days=1)).isoformat(),
        progress=40.0,
        estimated_remaining_hours=3.0,
        importance=5
    );
    _ = initialize_academic_task(
        student=student,
        task_id=DSA_QUIZ_ID,
        title=DSA_QUIZ_TITLE,
        deadline=(today + timedelta(days=2)).isoformat(),
        progress=20.0,
        estimated_remaining_hours=2.0,
        importance=4
    );
}


def initialize_budget(
    student: Student,
    weekly_budget: float,
    remaining_budget: float,
    days_remaining: int
) -> BudgetInitializationResult {
    validate_budget_values(
        weekly_budget,
        remaining_budget,
        days_remaining
    );
    existing = find_budget(student);
    if existing is not None {
        return BudgetInitializationResult(budget=existing, created=False);
    }
    budget = student +>:HasBudget():+> Budget(
        weekly_budget=weekly_budget,
        remaining_budget=remaining_budget,
        days_remaining=days_remaining
    );
    return BudgetInitializationResult(budget=budget, created=True);
}


def initialize_expense(
    budget: Budget,
    expense_id: str,
    amount: float,
    description: str,
    spent_on: str
) -> ExpenseInitializationResult {
    validate_expense_values(expense_id, amount, description);
    normalized_date = normalize_expense_date(spent_on);
    existing = find_expense(budget, expense_id);
    if existing is not None {
        return ExpenseInitializationResult(
            expense=existing,
            created=False
        );
    }
    expense = budget +>:HasExpense():+> Expense(
        expense_id=expense_id,
        amount=amount,
        description=description,
        spent_on=normalized_date
    );
    return ExpenseInitializationResult(expense=expense, created=True);
}


def initialize_demo_finance(student: Student) {
    budget_result = initialize_budget(
        student=student,
        weekly_budget=DEMO_WEEKLY_BUDGET,
        remaining_budget=DEMO_REMAINING_BUDGET,
        days_remaining=DEMO_DAYS_REMAINING
    );
    today = date.today();
    _ = initialize_expense(
        budget_result.budget,
        DEMO_PRIOR_EXPENSE_ID,
        2000.0,
        "Earlier weekly spending",
        (today - timedelta(days=1)).isoformat()
    );
    _ = initialize_expense(
        budget_result.budget,
        DEMO_TODAY_EXPENSE_ID,
        1500.0,
        "Today's spending",
        today.isoformat()
    );
}


def update_student_available_time(
    student_id: str,
    available_hours_today: float
) -> StudentStateView {
    validate_available_hours(available_hours_today);
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    student.available_hours_today = available_hours_today;
    return student.to_view();
}


def:pub initialize_demo_state -> StateInitializationResult {
    result = initialize_student(
        student_id=DEMO_STUDENT_ID,
        name=DEMO_STUDENT_NAME,
        life_stage=UNIVERSITY_LIFE_STAGE,
        available_hours_today=DEMO_AVAILABLE_HOURS
    );
    student = find_student(DEMO_STUDENT_ID);
    if student is None {
        raise RuntimeError("Demo student initialization failed.");
    }
    initialize_demo_academic_tasks(student);
    initialize_demo_finance(student);
    return result;
}


def:pub get_student_state -> StudentStateView | None {
    student = find_student(DEMO_STUDENT_ID);
    return student.to_view() if student is not None else None;
}


def:pub update_available_time(
    available_hours_today: float
) -> StudentStateView {
    return update_student_available_time(
        student_id=DEMO_STUDENT_ID,
        available_hours_today=available_hours_today
    );
}
