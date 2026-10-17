"""Non-persistent comparison of the current plan with a server simulation."""

import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    SlidersHorizontalIcon,
    RefreshIcon,
    Idea01Icon
}
import from .ui.button { Button }
import from .ui.spinner { Spinner }
import from .DeadlineRisk { RiskBadge }
import from .display { fmt_hours, fmt_money, level_of }
sv import from ..services.snapshot { StudentSnapshot }
sv import from ..agents.types { PlanningResponse }


glob SCENARIOS: list[dict[str, str]] = [
         {"key": "less_time", "label": "I have 2 fewer hours tonight"},
         {"key": "spend", "label": "I unexpectedly spend Rs. 2,000"},
         {"key": "finish_ml", "label": "I finish the ML assignment early"}
     ];


def:pub WhatIfPanel(
    scenario: str,
    running: bool,
    failed: bool,
    current: PlanningResponse,
    currentSnapshot: StudentSnapshot,
    simulated: PlanningResponse | None,
    simulatedSnapshot: StudentSnapshot | None,
    onPick: Callable[[str], None],
    onReset: Callable[[], None]
) -> JsxElement {
    def handle_reset(e: MouseEvent) {
        onReset();
    }

    return
        <section
            aria-labelledby="what-if"
            className="flex flex-col gap-5 rounded-xl border bg-card p-5 shadow-sm sm:p-6"
        >
            <header className="flex flex-wrap items-start justify-between gap-3">
                <div className="flex flex-col gap-0.5">
                    <h2
                        id="what-if"
                        className="flex items-center gap-2 text-lg font-semibold tracking-tight"
                    >
                        <HugeiconsIcon
                            icon={SlidersHorizontalIcon}
                            strokeWidth={2}
                            className="size-5 text-primary"
                        />
                        What-If Simulator
                    </h2>
                    <p className="text-sm text-muted-foreground">
                        Try a scenario. Your real data is never changed.
                    </p>
                </div>
                {scenario
                and <Button
                    variant="ghost"
                    size="sm"
                    onClick={handle_reset}
                    className="gap-1.5"
                >
                    <HugeiconsIcon
                        icon={RefreshIcon}
                        strokeWidth={2}
                        className="size-3.5"
                    />
                    Reset
                </Button>}
            </header>
            <div
                role="radiogroup"
                aria-label="Scenario"
                className="flex flex-wrap gap-2"
            >
                {for s in SCENARIOS {
                    <button
                        key={s["key"]}
                        type="button"
                        role="radio"
                        aria-checked={scenario == s["key"]}
                        disabled={running}
                        onClick={lambda (e: MouseEvent) { onPick(s["key"]); }}
                        className={"rounded-full border px-3.5 py-1.5 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 disabled:opacity-60 " + (
                            "border-primary bg-primary/10 text-primary"
                                if scenario == s["key"]
                                else "bg-card hover:bg-muted"
                        )}
                    >
                        {s["label"]}
                    </button>
                }}
            </div>
            {if not scenario {
                <p
                    className="rounded-lg border border-dashed px-4 py-5 text-center text-sm text-muted-foreground"
                >
                    Pick a scenario to compare it with your current plan.
                </p>
            } elif running {
                <p
                    className="flex items-center justify-center gap-2 rounded-lg border border-dashed px-4 py-8 text-sm text-muted-foreground"
                >
                    <Spinner className="size-4 text-primary"/>
                    Running the same agents on a copy of your data…
                </p>
            } elif simulated and simulatedSnapshot and not failed {
                <Comparison
                    current={current}
                    currentSnapshot={currentSnapshot}
                    simulated={simulated}
                    simulatedSnapshot={simulatedSnapshot}
                />
            } else {
                <p
                    className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-4 text-center text-sm"
                >
                    The simulation could not run right now. Your real plan is unchanged.
                </p>
            }   }
        </section>;
}


def Comparison(
    current: PlanningResponse,
    currentSnapshot: StudentSnapshot,
    simulated: PlanningResponse,
    simulatedSnapshot: StudentSnapshot
) -> JsxElement {
    return
        <div className="flex flex-col gap-4">
            <div className="grid gap-4 md:grid-cols-2">
                <ScenarioColumn
                    title="Current"
                    badge="Real data"
                    simulatedView={False}
                    plan={current}
                    snapshot={currentSnapshot}
                    compare={None}
                    compareSnapshot={None}
                />
                <ScenarioColumn
                    title="What-If"
                    badge="Simulated"
                    simulatedView={True}
                    plan={simulated}
                    snapshot={simulatedSnapshot}
                    compare={current}
                    compareSnapshot={currentSnapshot}
                />
            </div>
            <p className="flex items-start gap-2 text-sm">
                <HugeiconsIcon
                    icon={Idea01Icon}
                    strokeWidth={2}
                    className="mt-0.5 size-4 shrink-0 text-primary"
                />
                <span>
                    <span className="font-semibold">Why it changes: </span>
                    <span className="text-muted-foreground">
                        {simulated.coordinator.explanation}
                    </span>
                </span>
            </p>
        </div>;
}


def ScenarioColumn(
    title: str,
    badge: str,
    simulatedView: bool,
    plan: PlanningResponse,
    snapshot: StudentSnapshot,
    compare: PlanningResponse | None,
    compareSnapshot: StudentSnapshot | None
) -> JsxElement {
    shell = "border-2 border-dashed border-primary/40 bg-primary/[0.03]"
        if simulatedView
        else "border bg-muted/30";
    hours = snapshot.available_time.available_hours_today;
    money = snapshot.finance.remaining_budget;
    hours_changed = compareSnapshot
    and compareSnapshot.available_time.available_hours_today != hours;
    money_changed = compareSnapshot
    and compareSnapshot.finance.remaining_budget != money;
    action_changed = compare
    and compare.coordinator.next_action != plan.coordinator.next_action;

    return
        <div className={"flex flex-col gap-4 rounded-xl p-4 " + shell}>
            <div className="flex items-center justify-between">
                <span
                    className={"text-xs font-semibold uppercase tracking-wider " + (
                        "text-primary" if simulatedView else "text-muted-foreground"
                    )}
                >
                    {title}
                </span>
                <span
                    className={"rounded-full px-2 py-0.5 text-[11px] font-medium " + (
                        "bg-primary/10 text-primary"
                            if simulatedView
                            else "bg-muted text-muted-foreground"
                    )}
                >
                    {badge}
                </span>
            </div>
            <dl className="flex flex-col gap-2 text-sm">
                <CompareRow label="Available time" changed={hours_changed}>
                    <span className="font-medium tabular-nums">{fmt_hours(hours)}</span>
                </CompareRow>
                <CompareRow label="Budget left" changed={money_changed}>
                    <span className="font-medium tabular-nums">{fmt_money(money)}</span>
                </CompareRow>
                <CompareRow
                    label="Academic"
                    changed={compare
                    and level_of(compare.academic.urgency) != level_of(
                        plan.academic.urgency
                    )}
                >
                    <RiskBadge level={level_of(plan.academic.urgency)}/>
                </CompareRow>
                <CompareRow
                    label="Finance"
                    changed={compare
                    and level_of(compare.finance.urgency) != level_of(
                        plan.finance.urgency
                    )}
                >
                    <RiskBadge level={level_of(plan.finance.urgency)}/>
                </CompareRow>
                <CompareRow
                    label="Balance"
                    changed={compare
                    and level_of(compare.balance.urgency) != level_of(
                        plan.balance.urgency
                    )}
                >
                    <RiskBadge level={level_of(plan.balance.urgency)}/>
                </CompareRow>
            </dl>
            <div className="flex flex-col gap-1 border-t pt-3">
                <span
                    className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
                >
                    Best next action
                </span>
                <p
                    className={"text-sm font-semibold " + (
                        "text-primary" if action_changed else ""
                    )}
                >
                    {plan.coordinator.next_action}
                </p>
            </div>
        </div>;
}


def CompareRow(label: str, changed: any, children: any = None) -> JsxElement {
    return
        <div className="flex items-center justify-between gap-2">
            <dt className="flex items-center gap-2 text-muted-foreground">
                <span
                    className={"size-1.5 rounded-full " + (
                        "bg-primary" if changed else "bg-transparent"
                    )}
                />
                {label}
            </dt>
            <dd>{children}</dd>
        </div>;
}
