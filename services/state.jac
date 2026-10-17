"""Persistent student profile and available-time state for Lifora."""

glob DEMO_STUDENT_ID: str = "demo-student";
glob DEMO_STUDENT_NAME: str = "Demo Student";
glob UNIVERSITY_LIFE_STAGE: str = "university";
glob DEMO_AVAILABLE_HOURS: float = 5.0;


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


def validate_available_hours(available_hours_today: float) {
    if available_hours_today < 0.0 or available_hours_today > 24.0 {
        raise ValueError("Available hours today must be between 0 and 24.");
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
    return initialize_student(
        student_id=DEMO_STUDENT_ID,
        name=DEMO_STUDENT_NAME,
        life_stage=UNIVERSITY_LIFE_STAGE,
        available_hours_today=DEMO_AVAILABLE_HOURS
    );
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
