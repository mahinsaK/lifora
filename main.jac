import from services.finance { add_expense, get_finance }
import from services.planning { plan_student }
import from services.snapshot { get_student_snapshot }
import from services.state {
    get_student_state,
    initialize_demo_state,
    update_available_time
}
import from services.tasks { get_academic_tasks, update_task_progress }
import ".styles.global.css";
import from components.LiforaDashboard { LiforaDashboard }

def:pub app -> JsxElement {
    return <LiforaDashboard/>;
}
