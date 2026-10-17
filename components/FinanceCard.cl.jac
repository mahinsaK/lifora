import from "@hugeicons/core-free-icons" { Wallet01Icon, AddCircleIcon }
import from .ui.progress { Progress }
import from .StateCard { StateCard, AgentNote, WasValue }
import from .DeadlineRisk { LevelChange }
import from .display { fmt_money, level_of }
sv import from ..services.state { FinanceView }
sv import from ..agents.types { AgentResult }


def:pub FinanceCard(
    finance: FinanceView,
    agent: AgentResult | None,
    previousUrgency: str,
    previousRemaining: float,
    onAddExpense: Callable[[], None]
) -> JsxElement {
    weekly = finance.weekly_budget;
    used = weekly - finance.remaining_budget;
    used_pct = int(round(used / weekly * 100)) if weekly > 0 else 0;
    urgency = level_of(agent.urgency) if agent else "";
    note = agent.recommendation if agent else "";
    changed = previousRemaining >= 0 and previousRemaining != finance.remaining_budget;

    return <StateCard
        title="Finance"
        subtitle="Weekly budget"
        icon={Wallet01Icon}
        accent="bg-agent-finance"
        actionLabel="Add expense"
        actionIcon={AddCircleIcon}
        onAction={onAddExpense}
    >
        <div className="flex flex-col gap-1">
            <div className="flex items-end justify-between gap-2">
                <p className="flex flex-wrap items-baseline gap-x-2">
                    <span className="text-3xl font-semibold tabular-nums tracking-tight">{fmt_money(finance.remaining_budget)}</span>
                    <span className="text-sm text-muted-foreground">left this week</span>
                </p>
                {urgency and <LevelChange before={previousUrgency} after={urgency} />}
            </div>
            {changed and <div><WasValue previous={fmt_money(previousRemaining)} /></div>}
        </div>
        <div className="flex flex-col gap-3 rounded-lg border bg-muted/30 px-3 py-3">
            <div className="flex items-center justify-between text-xs">
                <span className="text-muted-foreground">Budget used</span>
                <span className="font-semibold tabular-nums">{str(used_pct) + "%"}</span>
            </div>
            <Progress value={used_pct} aria-label="Weekly budget used" className="h-1.5" />
            <dl className="grid grid-cols-3 gap-2 text-center">
                <div className="flex flex-col gap-0.5">
                    <dt className="text-[11px] uppercase tracking-wide text-muted-foreground">Weekly</dt>
                    <dd className="text-sm font-medium tabular-nums">{fmt_money(weekly)}</dd>
                </div>
                <div className="flex flex-col gap-0.5">
                    <dt className="text-[11px] uppercase tracking-wide text-muted-foreground">Today</dt>
                    <dd className="text-sm font-medium tabular-nums text-primary">{fmt_money(finance.spent_today)}</dd>
                </div>
                <div className="flex flex-col gap-0.5">
                    <dt className="text-[11px] uppercase tracking-wide text-muted-foreground">Days left</dt>
                    <dd className="text-sm font-medium tabular-nums">{str(finance.days_remaining)}</dd>
                </div>
            </dl>
        </div>
        <AgentNote agentName="Finance Agent" text={note} tone="text-agent-finance" />
    </StateCard>;
}
