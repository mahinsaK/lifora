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


edge HasAcademicTask: Student --> AcademicTask {}


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
