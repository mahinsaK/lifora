"""Stable StudentSnapshot composition for Lifora consumers."""

import from services.state {
    AcademicTaskView,
    AvailableTimeView,
    DEMO_STUDENT_ID,
    FinanceView,
    ProfileView,
    find_student
}
import from services.tasks { get_student_academic_tasks }
import from services.finance { get_student_finance }
import from services.student_management { get_student_goals }


obj StudentSnapshot {
    has profile: ProfileView;
    has academic_tasks: list[AcademicTaskView];
    has finance: FinanceView;
    has available_time: AvailableTimeView;
    has goals: list[str];
}


def build_student_snapshot(student_id: str) -> StudentSnapshot {
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    student_state = student.to_view();
    return StudentSnapshot(
        profile=student_state.profile,
        academic_tasks=get_student_academic_tasks(student_id),
        finance=get_student_finance(student_id),
        available_time=student_state.available_time,
        goals=[goal.title for goal in get_student_goals(student_id)]
    );
}


def:pub get_student_snapshot -> StudentSnapshot {
    return build_student_snapshot(DEMO_STUDENT_ID);
}
