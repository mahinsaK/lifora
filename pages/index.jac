import from ..components.ui.skeleton { Skeleton }
import from ..components.ui.button { Button }
import from ..components.HeroPanel { HeroPanel }
import from ..components.ResultStates { ThinkingResult, ErrorBanner }
import from ..components.PageParts { NextActionSummary }
import from ..components.OverviewPanels { DemoPath, QuickActions, SituationSummary }
import from ..components.LiforaProvider { useLifora }


"""/ - a presentation-first path from situation to one clear decision."""
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
        {app["planError"] and <ErrorBanner message={app["planError"]} hasPrevious={plan is not None} onRetry={app["runPlan"]} onDismiss={app["clearPlanError"]} />}

        {if plan {
            <NextActionSummary plan={plan} focusHours={app["focusHours"]} previousAction={previous["action"] or ""} busy={planning} />
        } elif planning {
            <ThinkingResult />
        }}

        {if app["booting"] {
            <div className="grid gap-3 md:grid-cols-3">{for i in [1, 2, 3] { <Skeleton key={str(i)} className="h-24 rounded-2xl" /> }}</div>
        } elif not snapshot {
            <div role="alert" className="flex flex-col items-center gap-3 rounded-2xl border bg-card px-6 py-10 text-center">
                <p className="font-semibold">{app["bootError"] or "No student data yet."}</p>
                <p className="text-sm text-muted-foreground">Check that the Lifora server is running, then try again.</p>
                <Button variant="outline" onClick={lambda (e: MouseEvent) { reload.call(None); }}>Retry</Button>
            </div>
        } else {
            <SituationSummary snapshot={snapshot} plan={plan} />
            <QuickActions onOpen={lambda (kind: str) { set_dialog.call(None, kind); }} />
            <DemoPath hasPlan={plan is not None} planning={planning} onRun={app["runPlan"]} onExpense={lambda { set_dialog.call(None, "expense"); }} />
        }}
    </div>;
}
