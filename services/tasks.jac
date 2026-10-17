"""Academic task operations backed by Lifora's persistent student graph."""

import from services.state {
    AcademicTaskView,
    DEMO_STUDENT_ID,
    HasAcademicTask,
    find_academic_task,
    find_student,
    initialize_academic_task,
    validate_academic_task_values,
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


def add_student_academic_task(
    student_id: str,
    task_id: str,
    title: str,
    deadline: str,
    progress: float,
    estimated_remaining_hours: float,
    importance: int
) -> AcademicTaskView {
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    if find_academic_task(student, task_id) is not None {
        raise ValueError(f"Academic task '{task_id}' already exists.");
    }
    result = initialize_academic_task(
        student=student,
        task_id=task_id,
        title=title,
        deadline=deadline,
        progress=progress,
        estimated_remaining_hours=estimated_remaining_hours,
        importance=importance
    );
    return result.task;
}


def update_student_academic_task(
    student_id: str,
    task_id: str,
    title: str,
    deadline: str,
    progress: float,
    estimated_remaining_hours: float,
    importance: int
) -> AcademicTaskView {
    normalized_deadline = validate_academic_task_values(
        task_id, title, deadline, progress, estimated_remaining_hours, importance
    );
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    task = find_academic_task(student, task_id);
    if task is None {
        raise ValueError(f"Academic task '{task_id}' was not found.");
    }
    task.title = title.strip();
    task.deadline = normalized_deadline;
    task.progress = progress;
    task.estimated_remaining_hours = estimated_remaining_hours;
    task.importance = importance;
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


def:pub add_academic_task(
    task_id: str,
    title: str,
    deadline: str,
    progress: float,
    estimated_remaining_hours: float,
    importance: int
) -> AcademicTaskView {
    return add_student_academic_task(
        student_id=DEMO_STUDENT_ID,
        task_id=task_id,
        title=title,
        deadline=deadline,
        progress=progress,
        estimated_remaining_hours=estimated_remaining_hours,
        importance=importance
    );
}


def:pub update_academic_task(
    task_id: str,
    title: str,
    deadline: str,
    progress: float,
    estimated_remaining_hours: float,
    importance: int
) -> AcademicTaskView {
    return update_student_academic_task(
        DEMO_STUDENT_ID,
        task_id,
        title,
        deadline,
        progress,
        estimated_remaining_hours,
        importance
    );
}


def:pub complete_academic_task(task_id: str) -> AcademicTaskView {
    return update_student_task_progress(DEMO_STUDENT_ID, task_id, 100.0);
}
