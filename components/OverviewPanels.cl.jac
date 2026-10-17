"""Presentation-focused overview sections for judges and first-time users."""

import from "@jac/runtime" { Link }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    AddCircleIcon,
    ArrowRight01Icon,
    BookOpen01Icon,
    HourglassIcon,
    InformationCircleIcon,
    SparklesIcon,
    Wallet01Icon
}
import from .ui.button { Button }
import from .DeadlineRisk { RiskBadge }
import from .display { fmt_hours, fmt_money, level_of }
sv import from ..services.snapshot { StudentSnapshot }
sv import from ..agents.types { PlanningResponse }


def MetricCard(
    label: str,
    value: str,
    detail: str,
    icon: any,
    risk: str = "",
    actionLabel: str = "",
    onAction: Callable[[], None] | None = None
) -> JsxElement {
    return <article className="flex min-w-0 items-center gap-4 rounded-2xl border bg-card px-4 py-4 shadow-sm sm:px-5">
        <span className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary">
            <HugeiconsIcon icon={icon} strokeWidth={2} className="size-5" />
        </span>
        <div className="min-w-0 flex-1">
            <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">{label}</p>
            <p className="truncate text-2xl font-semibold tracking-tight">{value}</p>
            <p className="text-xs leading-relaxed text-muted-foreground">{detail}</p>
            {actionLabel and onAction and <Button size="sm" variant="outline" className="mt-2 h-8" onClick={lambda (e: MouseEvent) { onAction(); }}>{actionLabel}</Button>}
        </div>
        {risk and <RiskBadge level={risk} />}
    </article>;
}


def:pub SituationSummary(
    snapshot: StudentSnapshot,
    plan: PlanningResponse | None,
    onAddTask: Callable[[], None]
) -> JsxElement {
    openTasks = len([task for task in snapshot.academic_tasks if task.progress < 100]);
    academicRisk = level_of(plan.academic.risk_level) if plan else "";
    financeRisk = level_of(plan.finance.urgency) if plan else "";
    balanceRisk = level_of(plan.balance.urgency) if plan else "";
    return <section aria-labelledby="situation" className="flex flex-col gap-3">
        <div className="flex items-end justify-between gap-3">
            <div>
                <p className="text-xs font-semibold uppercase tracking-wider text-primary">Inputs to your decision</p>
                <h2 id="situation" className="text-lg font-semibold tracking-tight">What Lifora is balancing right now</h2>
                <p className="text-sm text-muted-foreground">These three constraints shape the next action Lifora recommends.</p>
            </div>
            <Link to="/update" className="text-sm font-medium text-primary hover:underline">Update details</Link>
        </div>
        <div className="grid gap-3 md:grid-cols-3">
            <MetricCard
                label="Coursework pressure"
                value={(str(openTasks) + (" unfinished task" if openTasks == 1 else " unfinished tasks")) if len(snapshot.academic_tasks) > 0 else "No tasks yet"}
                detail={"Deadlines, progress, and work still required" if len(snapshot.academic_tasks) > 0 else "Add coursework so Lifora can include it in your decision"}
                icon={BookOpen01Icon}
                risk={academicRisk}
                actionLabel={"Add your first task" if len(snapshot.academic_tasks) == 0 else ""}
                onAction={onAddTask}
            />
            <MetricCard label="Spending room" value={fmt_money(snapshot.finance.remaining_budget)} detail={"Available for the next " + str(snapshot.finance.days_remaining) + " days"} icon={Wallet01Icon} risk={financeRisk} />
            <MetricCard label="Focus time left today" value={fmt_hours(snapshot.available_time.available_hours_today)} detail="Realistic study or work time after other commitments" icon={HourglassIcon} risk={balanceRisk} />
        </div>
        <p className="flex items-start gap-2 rounded-xl border border-primary/15 bg-primary/[0.04] px-4 py-3 text-sm text-muted-foreground"><HugeiconsIcon icon={InformationCircleIcon} strokeWidth={2} className="mt-0.5 size-4 shrink-0 text-primary" /><span><span className="font-semibold text-foreground">Focus time is not your whole evening.</span>{" It is the time you can realistically use after classes, travel, meals, rest, and other commitments."}</span></p>
    </section>;
}


def QuickAction(label: str, detail: str, icon: any, onPick: Callable[[], None]) -> JsxElement {
    return <button type="button" onClick={lambda (e: MouseEvent) { onPick(); }} className="group flex items-center gap-3 rounded-xl border bg-background px-3 py-3 text-left transition-all hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-sm focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50">
        <span className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={icon} strokeWidth={2} className="size-4" /></span>
        <span className="min-w-0"><span className="block text-sm font-semibold">{label}</span><span className="block truncate text-xs text-muted-foreground">{detail}</span></span>
    </button>;
}


def:pub QuickActions(onOpen: Callable[[str], None]) -> JsxElement {
    return <section aria-labelledby="quick-actions" className="rounded-2xl border bg-card p-4 shadow-sm sm:p-5">
        <div className="mb-4">
            <h2 id="quick-actions" className="font-semibold">Quick actions</h2>
            <p className="text-sm text-muted-foreground">Keep the three decision inputs accurate. Lifora handles the replanning.</p>
        </div>
        <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
            <QuickAction label="Add task" detail="Tell Lifora what is due" icon={BookOpen01Icon} onPick={lambda { onOpen("task"); }} />
            <QuickAction label="Add income" detail="Increase this week's spending room" icon={AddCircleIcon} onPick={lambda { onOpen("income"); }} />
            <QuickAction label="Add expense" detail="Reduce this week's spending room" icon={Wallet01Icon} onPick={lambda { onOpen("expense"); }} />
            <QuickAction label="Update focus time" detail="Set realistic hours left today" icon={HourglassIcon} onPick={lambda { onOpen("time"); }} />
        </div>
    </section>;
}


def:pub DemoPath(
    hasPlan: bool,
    planning: bool,
    onRun: Callable[[], None],
    onExpense: Callable[[], None]
) -> JsxElement {
    return <section aria-labelledby="demo-path" className="overflow-hidden rounded-2xl border border-primary/20 bg-gradient-to-br from-primary/[0.07] via-card to-card shadow-sm">
        <div className="flex flex-col gap-5 p-5 sm:p-6">
            <div className="flex items-start gap-3">
                <span className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary text-primary-foreground"><HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-5" /></span>
                <div>
                    <p className="text-xs font-semibold uppercase tracking-wider text-primary">60-second demo</p>
                    <h2 id="demo-path" className="text-lg font-semibold">See Lifora adapt to real life</h2>
                    <p className="text-sm text-muted-foreground">Follow three steps to see planning, automatic replanning, and safe simulation.</p>
                </div>
            </div>
            <ol className="grid gap-3 md:grid-cols-3">
                <li className="rounded-xl border bg-background/80 p-4"><span className="text-xs font-semibold text-primary">01 · Decide</span><p className="mt-1 text-sm font-medium">Choose the smartest next action</p><Button size="sm" className="mt-3 w-full" disabled={planning} onClick={lambda (e: MouseEvent) { onRun(); }}>{"Deciding…" if planning else ("Re-run decision" if hasPlan else "Find my next step")}</Button></li>
                <li className="rounded-xl border bg-background/80 p-4"><span className="text-xs font-semibold text-primary">02 · Adapt</span><p className="mt-1 text-sm font-medium">Log a surprise expense</p><Button size="sm" variant="outline" className="mt-3 w-full" onClick={lambda (e: MouseEvent) { onExpense(); }}>Add expense</Button></li>
                <li className="rounded-xl border bg-background/80 p-4"><span className="text-xs font-semibold text-primary">03 · Explore</span><p className="mt-1 text-sm font-medium">Test a change without saving it</p><Link to="/whatif" className="mt-3 inline-flex h-9 w-full items-center justify-center gap-2 rounded-lg border bg-background px-3 text-sm font-medium hover:bg-muted">Open What-If <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="size-4" /></Link></li>
            </ol>
            <p className="flex items-center gap-2 text-xs text-muted-foreground"><HugeiconsIcon icon={InformationCircleIcon} strokeWidth={2} className="size-4" />The demo uses the visible sample student data. What-If scenarios never alter saved data.</p>
        </div>
    </section>;
}
