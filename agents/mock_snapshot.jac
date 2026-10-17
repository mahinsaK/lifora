import from services.snapshot { StudentSnapshot }
import from services.state {
    AcademicTaskView as AcademicTask,
    AvailableTimeView as AvailableTime,
    FinanceView as FinanceSnapshot,
    ProfileView as Profile
}

def build_demo_snapshot -> StudentSnapshot {
    return StudentSnapshot(
        profile=Profile(name="Demo Student", life_stage="university"),
        academic_tasks=[
            AcademicTask(
                id="ml-assignment",
                title="Machine Learning Assignment",
                deadline="2026-10-18T23:59:00+05:30",
                progress=40.0,
                estimated_remaining_hours=3.0,
                importance=5
            ),
            AcademicTask(
                id="dsa-quiz",
                title="DSA Quiz",
                deadline="2026-10-19T23:59:00+05:30",
                progress=20.0,
                estimated_remaining_hours=2.0,
                importance=4
            )
        ],
        finance=FinanceSnapshot(
            weekly_budget=7000.0,
            remaining_budget=3500.0,
            spent_today=1500.0,
            days_remaining=4
        ),
        available_time=AvailableTime(available_hours_today=5.0),
        goals=[]
    );
}
