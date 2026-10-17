import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    BookOpen01Icon,
    Wallet01Icon,
    HourglassIcon,
    AiNetworkIcon,
    GitMergeIcon,
    CheckmarkCircle02Icon,
    ArrowDown01Icon,
    ArrowRight01Icon,
    Clock01Icon
}
import from .DeadlineRisk { LevelChange }
import from .display { fmt_hours, level_of }
sv import from ..agents.types { AgentResult, CoordinatorResult }


def:pub DecisionTrace(
    academic: AgentResult,
    finance: AgentResult,
    balance: AgentResult,
    coordinator: CoordinatorResult,
    previous: dict[str, str]
) -> JsxElement {
    conflicts = coordinator.conflicts;
    return <section aria-labelledby="decision-trace" className="flex flex-col gap-5 rounded-xl border bg-card p-5 shadow-sm sm:p-6">
        <header className="flex flex-wrap items-start justify-between gap-3">
            <div className="flex flex-col gap-0.5">
                <h2 id="decision-trace" className="text-lg font-semibold tracking-tight">Decision Trace</h2>
                <p className="text-sm text-muted-foreground">How 3 agents weighed in and how Lifora decided</p>
            </div>
            <span className="inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-medium text-muted-foreground">
                <span className="size-1.5 rounded-full bg-primary" />
                {str(len(conflicts)) + (" conflict resolved" if len(conflicts) == 1 else " conflicts resolved")}
            </span>
        </header>

        <div className="flex flex-col gap-2.5">
            <AgentRow
                name="Academic Agent"
                icon={BookOpen01Icon}
                tone="text-agent-academic"
                border="border-l-agent-academic"
                result={academic}
                previousUrgency={previous["academic"] or ""}
            />
            <AgentRow
                name="Finance Agent"
                icon={Wallet01Icon}
                tone="text-agent-finance"
                border="border-l-agent-finance"
                result={finance}
                previousUrgency={previous["finance"] or ""}
            />
            <AgentRow
                name="Balance Agent"
                icon={HourglassIcon}
                tone="text-agent-balance"
                border="border-l-agent-balance"
                result={balance}
                previousUrgency={previous["balance"] or ""}
            />
        </div>

        <div aria-hidden="true" className="flex items-center justify-center gap-2 text-xs font-medium text-muted-foreground">
            <span className="h-px flex-1 bg-border" />
            <HugeiconsIcon icon={ArrowDown01Icon} strokeWidth={2} className="size-4" />
            all three feed the Coordinator
            <HugeiconsIcon icon={ArrowDown01Icon} strokeWidth={2} className="size-4" />
            <span className="h-px flex-1 bg-border" />
        </div>

        <div className="flex flex-col gap-4 rounded-xl border border-l-4 border-primary/30 border-l-primary bg-primary/[0.04] p-4 sm:p-5">
            <p className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-primary">
                <HugeiconsIcon icon={AiNetworkIcon} strokeWidth={2} className="size-4" />
                Coordinator decision
            </p>

            {if len(conflicts) > 0 {
                <ul className="flex flex-col gap-2">
                    {for (i, c) in enumerate(conflicts) {
                        <li key={str(i)} className="flex items-start gap-2 rounded-lg border border-risk-medium/30 bg-risk-medium/10 px-3 py-2 text-sm">
                            <HugeiconsIcon icon={GitMergeIcon} strokeWidth={2} className="mt-0.5 size-4 shrink-0 text-risk-medium" />
                            <span><span className="font-semibold">Conflict: </span>{c}</span>
                        </li>
                    }}
                </ul>
            } else {
                <p className="flex items-center gap-2 rounded-lg bg-risk-low/10 px-3 py-2 text-sm text-risk-low">
                    <HugeiconsIcon icon={CheckmarkCircle02Icon} strokeWidth={2} className="size-4" />
                    No conflicts. The agents agreed on priorities.
                </p>
            }}

            <dl className="flex flex-col gap-3 text-sm">
                <div className="flex flex-col gap-0.5">
                    <dt className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Selected action</dt>
                    <dd className="font-semibold">{coordinator.next_action}</dd>
                </div>
                <div className="flex flex-col gap-0.5">
                    <dt className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Why it won</dt>
                    <dd className="leading-relaxed">{coordinator.explanation}</dd>
                </div>
            </dl>

            {if len(coordinator.deprioritized) > 0 {
                <div className="flex flex-col gap-2 border-t border-primary/15 pt-3">
                    <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Deprioritized for now</p>
                    <ul className="flex flex-col gap-1.5">
                        {for (i, d) in enumerate(coordinator.deprioritized) {
                            <li key={str(i)} className="flex items-start gap-2 text-sm text-muted-foreground">
                                <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="mt-0.5 size-4 shrink-0" />
                                {d}
                            </li>
                        }}
                    </ul>
                </div>
            }}
        </div>
    </section>;
}


def AgentRow(
    name: str,
    icon: any,
    tone: str,
    border: str,
    result: AgentResult,
    previousUrgency: str
) -> JsxElement {
    urgency = level_of(result.urgency);
    return <article className={"flex flex-col gap-1.5 rounded-lg border border-l-4 bg-muted/30 px-4 py-3 " + border}>
        <div className="flex flex-wrap items-center justify-between gap-2">
            <span className={"flex items-center gap-1.5 text-sm font-semibold " + tone}>
                <HugeiconsIcon icon={icon} strokeWidth={2} className="size-4" />
                {name}
            </span>
            <LevelChange before={previousUrgency} after={urgency} suffix="urgency" />
        </div>
        <p className="text-sm font-semibold leading-snug">{result.recommendation}</p>
        <p className="text-sm leading-relaxed text-muted-foreground">{result.reasoning}</p>
        {result.required_time > 0 and <p className="flex items-center gap-1 text-xs text-muted-foreground">
            <HugeiconsIcon icon={Clock01Icon} strokeWidth={2} className="size-3.5" />
            {"Needs about " + fmt_hours(result.required_time)}
        </p>}
    </article>;
}
