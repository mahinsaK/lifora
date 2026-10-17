import from "@hugeicons/core-free-icons" { BookOpen01Icon, ChartIncreaseIcon }
import from .ui.progress { Progress }
import from .StateCard { StateCard, AgentNote }
import from .DeadlineRisk { LevelChange }
import from .display { deadline_label, days_until, fmt_hours, level_of }
sv import from ..services.state { AcademicTaskView }
sv import from ..agents.types { AgentResult }


def:pub AcademicCard(
    tasks: list[AcademicTaskView],
    agent: AgentResult | None,
    previousRisk: str,
    changedTaskId: str,
    previousProgress: float,
    onUpdate: Callable[[], None]
) -> JsxElement {
    open_tasks = [t for t in tasks if t.progress < 100];
    risk = level_of(agent.risk_level) if agent else "";
    note = agent.recommendation if agent else "";

    return <StateCard
        title="Academic"
        subtitle="Deadlines & coursework"
        icon={BookOpen01Icon}
        accent="bg-agent-academic"
        actionLabel="Update progress"
        actionIcon={ChartIncreaseIcon}
        onAction={onUpdate}
        actionDisabled={len(tasks) == 0}
    >
        <div className="flex items-end justify-between gap-2">
            <p className="flex items-baseline gap-2">
                <span className="text-3xl font-semibold tabular-nums tracking-tight">{len(open_tasks)}</span>
                <span className="text-sm text-muted-foreground">{"open task" if len(open_tasks) == 1 else "open tasks"}</span>
            </p>
            {risk and <LevelChange before={previousRisk} after={risk} suffix="risk" />}
        </div>
        <ul className="flex flex-col gap-2.5">
            {for task in tasks {
                <TaskRow
                    key={task.id}
                    task={task}
                    changed={task.id == changedTaskId}
                    previousProgress={previousProgress}
                />
            }}
            {if len(tasks) == 0 {
                <li className="rounded-lg border border-dashed px-3 py-4 text-center text-sm text-muted-foreground">No academic tasks yet.</li>
            }}
        </ul>
        <AgentNote agentName="Academic Agent" text={note} tone="text-agent-academic" />
    </StateCard>;
}


def TaskRow(task: AcademicTaskView, changed: bool, previousProgress: float) -> JsxElement {
    days = days_until(task.deadline);
    due_tone = "text-risk-high font-medium" if days <= 1 else "text-muted-foreground";
    done = task.progress >= 100;
    pct = int(round(task.progress));
    return <li className={"flex flex-col gap-2 rounded-lg border bg-muted/30 px-3 py-2.5 transition-colors " + ("border-primary/40 bg-primary/5" if changed else "")}>
        <div className="flex items-center justify-between gap-2">
            <span className={"truncate text-sm font-medium " + ("text-muted-foreground line-through" if done else "")}>{task.title}</span>
            <span className={"shrink-0 text-xs " + due_tone}>{"Done" if done else deadline_label(task.deadline)}</span>
        </div>
        <Progress
            value={pct}
            aria-label={task.title + " progress"}
            className="h-1.5"
        />
        <div className="flex items-center justify-between gap-2 text-xs text-muted-foreground">
            <span className="flex items-center gap-1.5 tabular-nums">
                <span className="font-semibold text-foreground">{str(pct) + "%"}</span>
                {changed and <span className="text-primary">{"(was " + str(int(round(previousProgress))) + "%)"}</span>}
            </span>
            <span className="tabular-nums">{("~" + fmt_hours(task.estimated_remaining_hours) + " left") if not done else "Complete"}</span>
        </div>
    </li>;
}
