import from "@hugeicons/core-free-icons" { HourglassIcon, Edit02Icon }
import from .StateCard { StateCard, AgentNote, WasValue }
import from .DeadlineRisk { LevelChange }
import from .display { PlanStep, fmt_hours, level_of }
sv import from ..agents.types { AgentResult }


"""Available Time card - the Balance Agent's domain."""
def:pub BalanceCard(
    hours: float,
    previousHours: float,
    agent: AgentResult | None,
    steps: list[PlanStep],
    previousUrgency: str,
    onEdit: Callable[[], None]
) -> JsxElement {
    focus = 0.0;
    rest = 0.0;
    for step in steps {
        if step.kind == "break" {
            rest = rest + step.hours;
        } else {
            focus = focus + step.hours;
        }
    }
    free = hours - focus - rest;
    free = 0.0 if free < 0 else free;
    planned = len(steps) > 0;
    urgency = level_of(agent.urgency) if agent else "";
    note = agent.recommendation if agent else "";
    changed = previousHours >= 0 and previousHours != hours;

    return <StateCard
        title="Available Time"
        subtitle="Tonight's capacity"
        icon={HourglassIcon}
        accent="bg-agent-balance"
        actionLabel="Edit time"
        actionIcon={Edit02Icon}
        onAction={onEdit}
    >
        <div className="flex flex-col gap-1">
            <div className="flex items-end justify-between gap-2">
                <p className="flex items-baseline gap-2">
                    <span className="text-3xl font-semibold tabular-nums tracking-tight">{fmt_hours(hours)}</span>
                    <span className="text-sm text-muted-foreground">available tonight</span>
                </p>
                {urgency and <LevelChange before={previousUrgency} after={urgency} />}
            </div>
            {changed and <div><WasValue previous={fmt_hours(previousHours)} /></div>}
        </div>
        <div className="flex flex-col gap-3 rounded-lg border bg-muted/30 px-3 py-3">
            {if planned {
                <div className="flex h-2 w-full overflow-hidden rounded-full bg-muted" aria-hidden="true">
                    <span className="h-full bg-primary" style={{"width": str(focus / hours * 100 if hours > 0 else 0) + "%"}} />
                    <span className="h-full bg-muted-foreground/40" style={{"width": str(rest / hours * 100 if hours > 0 else 0) + "%"}} />
                </div>
                <dl className="flex flex-col gap-1.5 text-sm">
                    <TimeRow dot="bg-primary" label="Planned focus" value={fmt_hours(focus)} />
                    <TimeRow dot="bg-muted-foreground/40" label="Breaks" value={fmt_hours(rest)} />
                    <TimeRow dot="bg-agent-balance/40" label="Free / buffer" value={fmt_hours(free)} />
                </dl>
            } else {
                <p className="text-sm text-muted-foreground">Lifora will split this time into realistic focus blocks and breaks.</p>
            }}
        </div>
        <AgentNote agentName="Balance Agent" text={note} tone="text-agent-balance" />
    </StateCard>;
}


def TimeRow(dot: str, label: str, value: str) -> JsxElement {
    return <div className="flex items-center justify-between gap-2">
        <dt className="flex items-center gap-2 text-muted-foreground">
            <span className={"size-2 rounded-full " + dot} />
            {label}
        </dt>
        <dd className="font-medium tabular-nums">{value}</dd>
    </div>;
}
