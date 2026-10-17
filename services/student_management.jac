"""Profile and goal operations kept separate from snapshot composition."""

import from services.state {
    DEMO_STUDENT_ID,
    Goal,
    GoalView,
    HasGoal,
    ProfileView,
    find_goal,
    find_student
}


def get_student_goals(student_id: str) -> list[GoalView] {
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    goals = [goal.to_view() for goal in [student ->:HasGoal:->]];
    return sorted(goals, key=lambda (goal: GoalView) { goal.title + goal.id; });
}


def update_student_profile(student_id: str, name: str, life_stage: str) -> ProfileView {
    if not name.strip() {
        raise ValueError("Student name is required.");
    }
    if not life_stage.strip() {
        raise ValueError("Life stage is required.");
    }
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    student.name = name.strip();
    student.life_stage = life_stage.strip();
    return student.to_view().profile;
}


def add_student_goal(student_id: str, goal_id: str, title: str) -> GoalView {
    if not goal_id.strip() {
        raise ValueError("Goal ID is required.");
    }
    if not title.strip() {
        raise ValueError("Goal title is required.");
    }
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    if find_goal(student, goal_id) is not None {
        raise ValueError(f"Goal '{goal_id}' already exists.");
    }
    goal = student +>:HasGoal():+> Goal(goal_id=goal_id, title=title.strip());
    return goal.to_view();
}


def remove_student_goal(student_id: str, goal_id: str) -> list[GoalView] {
    student = find_student(student_id);
    if student is None {
        raise ValueError(f"Student '{student_id}' was not found.");
    }
    goal = find_goal(student, goal_id);
    if goal is None {
        raise ValueError(f"Goal '{goal_id}' was not found.");
    }
    del goal;
    return get_student_goals(student_id);
}


def:pub get_goals -> list[GoalView] {
    return get_student_goals(DEMO_STUDENT_ID);
}


def:pub update_profile(name: str, life_stage: str) -> ProfileView {
    return update_student_profile(DEMO_STUDENT_ID, name, life_stage);
}


def:pub add_goal(goal_id: str, title: str) -> GoalView {
    return add_student_goal(DEMO_STUDENT_ID, goal_id, title);
}


def:pub remove_goal(goal_id: str) -> list[GoalView] {
    return remove_student_goal(DEMO_STUDENT_ID, goal_id);
}
