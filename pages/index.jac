import from ..components.ui.skeleton { Skeleton }
import from ..components.ui.button { Button }
import from ..components.HeroPanel { HeroPanel }
import from ..components.AcademicCard { AcademicCard }
import from ..components.FinanceCard { FinanceCard }
import from ..components.BalanceCard { BalanceCard }
import from ..components.ResultStates { EmptyResult, ThinkingResult, ErrorBanner }
import from ..components.PageParts { NextActionSummary }
import from ..components.LiforaProvider { useLifora }


"""/ - who the student is, their current state, and the main Lifora action."""
def:pub OverviewPage -> JsxPage {
    app = useLifora();
    snapshot = app["snapshot"];
    plan = app["plan"];
    planning: bool = app["planning"];
    previous = app["previous"];
    set_dialog = app["setDialog"];
    reload = app["reload"];
    name = snapshot.profile.name if snapshot else "Student";

    return <div className="flex flex-col gap-6">
        <HeroPanel
            name={name}
            thinking={planning}
            hasResult={plan is not None}
            stale={app["stale"]}
            lastRun={app["lastRun"]}
            disabled={app["booting"] or not snapshot}
            onRun={app["runPlan"]}
        />
        {app["planError"] and <ErrorBanner
            message={app["planError"]}
            hasPrevious={plan is not None}
            onRetry={app["runPlan"]}
            onDismiss={app["clearPlanError"]}
        />}

        {if plan {
            <NextActionSummary
                plan={plan}
                focusHours={app["focusHours"]}
                previousAction={previous["action"] or ""}
                busy={planning}
            />
        } elif planning {
            <ThinkingResult />
        }}

        <section aria-labelledby="situation" className="flex flex-col gap-3">
            <h2 id="situation" className="text-sm font-semibold uppercase tracking-wider text-muted-foreground">Your situation</h2>
            {if app["booting"] {
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    {for i in [1, 2, 3] {
                        <div key={str(i)} className="flex flex-col gap-4 rounded-xl border bg-card p-5 shadow-sm">
                            <Skeleton className="h-10 w-40" />
                            <Skeleton className="h-9 w-28" />
                            <Skeleton className="h-24 w-full" />
                        </div>
                    }}
                </div>
            } elif not snapshot {
                <div role="alert" className="flex flex-col items-center gap-3 rounded-xl border bg-card px-6 py-10 text-center">
                    <p className="font-semibold">{app["bootError"] or "No student data yet."}</p>
                    <p className="text-sm text-muted-foreground">Check that the Lifora server is running, then try again.</p>
                    <Button variant="outline" onClick={lambda (e: MouseEvent) { reload.call(None); }}>Retry</Button>
                </div>
            } else {
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    <AcademicCard
                        tasks={snapshot.academic_tasks}
                        agent={plan.academic if plan else None}
                        previousRisk={previous["academicRisk"] or ""}
                        changedTaskId={app["changedTaskId"]}
                        previousProgress={app["previousProgress"]}
                        onUpdate={lambda { set_dialog.call(None, "progress"); }}
                    />
                    <FinanceCard
                        finance={snapshot.finance}
                        agent={plan.finance if plan else None}
                        previousUrgency={previous["finance"] or ""}
                        previousRemaining={app["previousRemaining"]}
                        onAddExpense={lambda { set_dialog.call(None, "expense"); }}
                    />
                    <div className="md:col-span-2 lg:col-span-1 [&>article]:h-full">
                        <BalanceCard
                            hours={snapshot.available_time.available_hours_today}
                            previousHours={app["previousHours"]}
                            agent={plan.balance if plan else None}
                            steps={app["steps"]}
                            previousUrgency={previous["balance"] or ""}
                            onEdit={lambda { set_dialog.call(None, "time"); }}
                        />
                    </div>
                </div>
            }}
        </section>

        {if not plan and not planning and snapshot {
            <EmptyResult onRun={app["runPlan"]} disabled={False} />
        }}
    </div>;
}
