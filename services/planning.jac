import from agents.pipeline { run_pipeline }
import from agents.types { PlanningResponse }
import from services.snapshot { StudentSnapshot }

async def:pub plan_student(snapshot: StudentSnapshot) -> PlanningResponse {
    return await run_pipeline(snapshot);
}
