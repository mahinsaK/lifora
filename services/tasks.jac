"""Academic task operations backed by Lifora's persistent student graph."""

import from services.state {
    AcademicTaskView,
    DEMO_STUDENT_ID,
    HasAcademicTask,
    find_academic_task,
    find_student,
    validate_task_progress
}


def get_student_academic_tasks(
    student_id: str
) -> list[AcademicTaskView] {
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }

    tasks = [task.to_view() for task in [student ->:HasAcademicTask:->]];
    return sorted(
        tasks,
        key=lambda (task: AcademicTaskView) {
            task.deadline + task.id;
        }
    );
}


def update_student_task_progress(
    student_id: str,
    task_id: str,
    progress: float
) -> AcademicTaskView {
    validate_task_progress(progress);
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    task = find_academic_task(student, task_id);
    if task is None {
        raise ValueError(f"Academic task '{task_id}' was not found.");
    }
    task.progress = progress;
    return task.to_view();
}


def:pub get_academic_tasks -> list[AcademicTaskView] {
    return get_student_academic_tasks(DEMO_STUDENT_ID);
}


def:pub update_task_progress(
    task_id: str,
    progress: float
) -> AcademicTaskView {
    return update_student_task_progress(
        student_id=DEMO_STUDENT_ID,
        task_id=task_id,
        progress=progress
    );
}
