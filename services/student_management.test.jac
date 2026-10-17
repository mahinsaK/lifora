import from services.state { HasGoal, find_student, initialize_student }
import from test_support { assert_value_error }


def remove_management_student(student_id: str) {
    student = find_student(student_id);
    if student is not None {
        for goal in [student ->:HasGoal:->] {
            del goal;
        }
        del student;
    }
}


test "profile and goals persist through the student graph" {
    student_id = "management-fixture";
    remove_management_student(student_id);
    _ = initialize_student(student_id, "Original", "university", 5.0);

    profile = update_student_profile(student_id, "Lumith", "undergraduate");
    assert profile.name == "Lumith";
    assert profile.life_stage == "undergraduate";
    first = add_student_goal(student_id, "goal-1", "Finish the semester strongly");
    second = add_student_goal(student_id, "goal-2", "Stay within budget");
    assert first.title == "Finish the semester strongly";
    assert second.title == "Stay within budget";
    assert len(get_student_goals(student_id)) == 2;

    remaining = remove_student_goal(student_id, "goal-1");
    assert len(remaining) == 1;
    assert remaining[0].id == "goal-2";
    remove_management_student(student_id);
}


test "profile and goal validation does not mutate state" {
    student_id = "management-validation-fixture";
    remove_management_student(student_id);
    _ = initialize_student(student_id, "Original", "university", 5.0);
    assert_value_error(lambda { update_student_profile(student_id, "", "student"); }, "name is required");
    assert_value_error(lambda { add_student_goal(student_id, "goal-1", ""); }, "title is required");
    assert_value_error(lambda { remove_student_goal(student_id, "missing"); }, "was not found");
    assert find_student(student_id)?.name == "Original";
    assert len(get_student_goals(student_id)) == 0;
    remove_management_student(student_id);
}
