import from services.finance {
    add_expense,
    add_income,
    get_finance,
    get_transactions
}
import from services.planning { WhatIfResponse, plan_student, simulate_plan }
import from services.snapshot { get_student_snapshot }
import from services.student_management {
    add_goal,
    get_goals,
    remove_goal,
    update_profile
}
import from services.task_estimation { estimate_task_hours }
import from services.state {
    get_student_state,
    initialize_demo_state,
    update_available_time
}
import from services.tasks {
    add_academic_task,
    complete_academic_task,
    get_academic_tasks,
    update_academic_task,
    update_task_progress
}
import ".styles.global.css";
import from components.LiforaProvider { LiforaProvider }

# File-based routing: pages/ builds the router and passes it in as `children`.
def:pub app(children: any) -> JsxElement {
    return <LiforaProvider>{children}</LiforaProvider>;
}
