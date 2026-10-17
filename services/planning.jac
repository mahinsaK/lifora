import from agents.pipeline { run_pipeline }
import from agents.types { PlanningResponse, StudentSnapshot }

async def:pub plan_student(snapshot: StudentSnapshot) -> PlanningResponse {
    return await run_pipeline(snapshot);
}
