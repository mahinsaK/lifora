import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { AiNetworkIcon, ArrowDown01Icon }
import from ..components.NextAction { NextAction }
import from ..components.DailyPlan { DailyPlan }
import from ..components.BalanceCard { BalanceCard }
import from ..components.DecisionTrace { DecisionTrace }
import from ..components.ResultStates { ErrorBanner }
import from ..components.PageParts { PageHeader, RunButton, NoPlanYet }
import from ..components.LiforaProvider { useLifora }


"""/plan - the Coordinator's decision for tonight: Best Next Action + Daily Plan."""
def:pub PlanPage -> JsxPage {
    app = useLifora();
    snapshot = app["snapshot"];
    plan = app["plan"];
    planning: bool = app["planning"];
    previous = app["previous"];
    set_dialog = app["setDialog"];
    subtitle = ("Planned at " + app["lastRun"]) if app["lastRun"] else "Your best next step and an ordered plan for tonight.";
    if app["stale"] {
        subtitle = "Your situation changed. Replanning keeps this up to date.";
    }

    return <div className="flex flex-col gap-6">
        <PageHeader eyebrow="Tonight" title="Your plan" description={subtitle}>
            <RunButton
                planning={planning}
                hasPlan={plan is not None}
                stale={app["stale"]}
                disabled={app["booting"] or not snapshot}
                onRun={app["runPlan"]}
            />
        </PageHeader>
        {app["planError"] and <ErrorBanner
            message={app["planError"]}
            hasPrevious={plan is not None}
            onRetry={app["runPlan"]}
            onDismiss={app["clearPlanError"]}
        />}

        {if not plan {
            <NoPlanYet what="plan" planning={planning} disabled={app["booting"] or not snapshot} onRun={app["runPlan"]} />
        } else {
        <div className={"flex flex-col gap-6 transition-opacity " + ("pointer-events-none opacity-60" if planning else "")}>
            <NextAction
                coordinator={plan.coordinator}
                academic={plan.academic}
                focusHours={app["focusHours"]}
                previousAction={previous["action"] or ""}
            />
            <div className="grid items-start gap-6 lg:grid-cols-12">
                <div className="lg:col-span-7">
                    <DailyPlan steps={app["steps"]} startMinutes={app["planStart"]} />
                </div>
                <div className="flex flex-col gap-4 lg:col-span-5">
                    {snapshot and <BalanceCard
                        hours={snapshot.available_time.available_hours_today}
                        previousHours={app["previousHours"]}
                        agent={plan.balance}
                        steps={app["steps"]}
                        previousUrgency={previous["balance"] or ""}
                        onEdit={lambda { set_dialog.call(None, "time"); }}
                    />}
                    <a href="#why" className="group flex items-center justify-between gap-3 rounded-xl border bg-card p-4 shadow-sm transition-colors hover:border-primary/40 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50">
                        <span className="flex items-center gap-3">
                            <span className="flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary">
                                <HugeiconsIcon icon={AiNetworkIcon} strokeWidth={2} className="size-5" />
                            </span>
                            <span className="flex flex-col">
                                <span className="text-sm font-semibold">Why this plan?</span>
                                <span className="text-xs text-muted-foreground">See what each specialist noticed</span>
                            </span>
                        </span>
                        <HugeiconsIcon icon={ArrowDown01Icon} strokeWidth={2} className="size-4 text-muted-foreground transition-transform group-hover:translate-y-0.5" />
                    </a>
                </div>
            </div>
            <details id="why" className="group rounded-2xl border bg-card shadow-sm">
                <summary className="flex cursor-pointer list-none items-center justify-between gap-4 px-5 py-4 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 sm:px-6">
                    <span className="flex items-center gap-3"><span className="flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={AiNetworkIcon} strokeWidth={2} className="size-5" /></span><span><span className="block font-semibold">Why Lifora chose this plan</span><span className="block text-sm text-muted-foreground">Academic, finance, and balance reasoning</span></span></span>
                    <HugeiconsIcon icon={ArrowDown01Icon} strokeWidth={2} className="size-4 transition-transform group-open:rotate-180" />
                </summary>
                <div className="border-t p-4 sm:p-6">
                    <DecisionTrace academic={plan.academic} finance={plan.finance} balance={plan.balance} coordinator={plan.coordinator} previous={previous} />
                </div>
            </details>
        </div>
        }}
    </div>;
}
