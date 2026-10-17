import from "@jac/runtime" { Link }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    SparklesIcon,
    RefreshIcon,
    ArrowRight01Icon,
    FlashIcon,
    Clock01Icon
}
import from .ui.button { Button }
import from .ui.spinner { Spinner }
import from .DeadlineRisk { RiskBadge }
import from .display { fmt_hours, level_of }
sv import from ..agents.types { PlanningResponse }


"""Title block at the top of every page except Overview."""
def:pub PageHeader(eyebrow: str, title: str, description: str, children: any = None) -> JsxElement {
    return <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div className="flex max-w-2xl flex-col gap-1">
            <p className="text-xs font-semibold uppercase tracking-wider text-primary">{eyebrow}</p>
            <h1 className="text-2xl font-semibold tracking-tight sm:text-3xl">{title}</h1>
            <p className="text-sm text-muted-foreground sm:text-base">{description}</p>
        </div>
        {children and <div className="flex shrink-0 flex-wrap gap-2">{children}</div>}
    </div>;
}


"""Primary run / re-run button shared by pages."""
def:pub RunButton(planning: bool, hasPlan: bool, stale: bool, disabled: bool, onRun: Callable[[], None]) -> JsxElement {
    def handle(e: MouseEvent) {
        onRun();
    }
    label = "What Should I Do Next?";
    if hasPlan {
        label = "Replan with your changes" if stale else "Re-run Lifora";
    }
    return <Button onClick={handle} disabled={planning or disabled} className="h-10 gap-2 px-4 shadow-sm">
        {planning and <Spinner className="size-4" />}
        {not planning and <HugeiconsIcon icon={RefreshIcon if hasPlan else SparklesIcon} strokeWidth={2} className="size-4" />}
        {"Lifora is thinking…" if planning else label}
    </Button>;
}


"""Shown on Plan / Trace pages before Lifora has produced a plan."""
def:pub NoPlanYet(what: str, planning: bool, disabled: bool, onRun: Callable[[], None]) -> JsxElement {
    def handle(e: MouseEvent) {
        onRun();
    }
    return <section className="flex flex-col items-center gap-4 rounded-2xl border-2 border-dashed border-primary/20 bg-card/60 px-6 py-14 text-center">
        <span className="flex size-14 items-center justify-center rounded-full bg-primary/10 text-primary">
            {planning and <Spinner className="size-6" />}
            {not planning and <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-7" />}
        </span>
        <div className="flex max-w-md flex-col gap-1.5">
            <h2 className="text-lg font-semibold">{"Lifora is thinking…" if planning else "No plan yet"}</h2>
            <p className="text-sm text-muted-foreground">
                {"The specialist agents are weighing your deadlines, budget and time." if planning else "Ask Lifora what to do next and your " + what + " will appear here."}
            </p>
        </div>
        {not planning and <Button onClick={handle} disabled={disabled} className="gap-2">
            <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-4" />
            What Should I Do Next?
        </Button>}
    </section>;
}


"""Compact Best Next Action shown on the Overview, linking to the full pages."""
def:pub NextActionSummary(plan: PlanningResponse, focusHours: float, previousAction: str, busy: bool) -> JsxElement {
    risk = level_of(plan.academic.risk_level);
    changed = previousAction and previousAction != plan.coordinator.next_action;
    return <section aria-labelledby="summary-action" className={"relative overflow-hidden rounded-2xl border border-primary/30 bg-card shadow-md shadow-primary/5 transition-opacity " + ("opacity-60" if busy else "")}>
        <span aria-hidden="true" className="absolute inset-x-0 top-0 h-1 bg-primary" />
        <div className="flex flex-col gap-4 px-5 pt-6 pb-5 sm:px-7 lg:flex-row lg:items-center lg:justify-between">
            <div className="flex flex-col gap-2">
                <p id="summary-action" className="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-primary">
                    <HugeiconsIcon icon={FlashIcon} strokeWidth={2} className="size-4" />
                    Best next action
                    {changed and <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] normal-case tracking-normal">Updated</span>}
                </p>
                <h2 className="text-balance text-xl font-semibold leading-snug tracking-tight sm:text-2xl">{plan.coordinator.next_action}</h2>
                <div className="flex flex-wrap items-center gap-2">
                    <RiskBadge level={risk} suffix="deadline risk" />
                    {focusHours > 0 and <span className="inline-flex h-6 items-center gap-1.5 rounded-full border px-2.5 text-xs font-medium">
                        <HugeiconsIcon icon={Clock01Icon} strokeWidth={2} className="size-3.5" />
                        {fmt_hours(focusHours) + " focused work"}
                    </span>}
                </div>
            </div>
            <div className="flex shrink-0 flex-col gap-2 sm:flex-row">
                <Link to="/plan" className="inline-flex h-10 items-center justify-center gap-2 rounded-lg bg-primary px-4 text-sm font-medium text-primary-foreground shadow-sm transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50">
                    See tonight's plan
                    <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="size-4" />
                </Link>
                <Link to="/trace" className="inline-flex h-10 items-center justify-center gap-2 rounded-lg border bg-card px-4 text-sm font-medium transition-colors hover:bg-muted focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50">
                    Why this?
                </Link>
            </div>
        </div>
    </section>;
}
