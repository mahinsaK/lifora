import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { FlashIcon, Clock01Icon, Wallet01Icon, ArrowTurnBackwardIcon }
import from .DeadlineRisk { RiskBadge, DeadlineRiskAlert }
import from .display { fmt_hours, level_of }
sv import from ..agents.types { AgentResult, CoordinatorResult }


def:pub NextAction(
    coordinator: CoordinatorResult,
    academic: AgentResult,
    focusHours: float,
    previousAction: str
) -> JsxElement {
    risk = level_of(academic.risk_level);
    changed = previousAction and previousAction != coordinator.next_action;

    return <section aria-labelledby="best-next-action" className="relative overflow-hidden rounded-2xl border border-primary/30 bg-card shadow-md shadow-primary/5">
        <span aria-hidden="true" className="absolute inset-x-0 top-0 h-1 bg-primary" />
        <div className="flex flex-col gap-5 px-5 pt-7 pb-5 sm:px-8">
            <p id="best-next-action" className="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-primary">
                <HugeiconsIcon icon={FlashIcon} strokeWidth={2} className="size-4" />
                Best next action
            </p>
            <div className="flex flex-col gap-3">
                <h2 className="text-balance text-2xl font-semibold leading-tight tracking-tight sm:text-3xl">{coordinator.next_action}</h2>
                {changed and <p className="flex items-start gap-1.5 text-sm text-muted-foreground">
                    <HugeiconsIcon icon={ArrowTurnBackwardIcon} strokeWidth={2} className="mt-0.5 size-4 shrink-0" />
                    <span>Previously: <span className="line-through">{previousAction}</span></span>
                </p>}
                <p className="max-w-3xl text-base leading-relaxed">
                    <span className="font-semibold">Why: </span>
                    <span className="text-muted-foreground">{coordinator.explanation}</span>
                </p>
            </div>
            <DeadlineRiskAlert level={risk} summary={academic.summary} />
        </div>
        <div className="flex flex-col gap-3 border-t bg-muted/40 px-5 py-4 sm:px-8 lg:flex-row lg:items-center lg:justify-between">
            <div className="flex flex-wrap items-center gap-2">
                {focusHours > 0 and <span className="inline-flex h-6 items-center gap-1.5 rounded-full border bg-card px-2.5 text-xs font-medium">
                    <HugeiconsIcon icon={Clock01Icon} strokeWidth={2} className="size-3.5" />
                    {fmt_hours(focusHours) + " focused work"}
                </span>}
                <RiskBadge level={risk} suffix="deadline risk" />
            </div>
            {coordinator.finance_action and <p className="flex items-start gap-2 rounded-lg border bg-card px-3 py-2 text-sm lg:max-w-md">
                <HugeiconsIcon icon={Wallet01Icon} strokeWidth={2} className="mt-0.5 size-4 shrink-0 text-agent-finance" />
                <span><span className="font-semibold">Money: </span>{coordinator.finance_action}</span>
            </p>}
        </div>
    </section>;
}
