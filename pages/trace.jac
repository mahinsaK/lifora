import from ..components.DecisionTrace { DecisionTrace }
import from ..components.ResultStates { ErrorBanner }
import from ..components.PageParts { PageHeader, RunButton, NoPlanYet }
import from ..components.LiforaProvider { useLifora }


"""/trace - proof of multi-agent coordination: specialists, conflicts, decision."""
def:pub TracePage -> JsxPage {
    app = useLifora();
    plan = app["plan"];
    planning: bool = app["planning"];

    return <div className="flex flex-col gap-6">
        <PageHeader
            eyebrow="Explainability"
            title="Decision Trace"
            description="What each specialist agent recommended, where they disagreed, and why Lifora chose what it did."
        >
            <RunButton
                planning={planning}
                hasPlan={plan is not None}
                stale={app["stale"]}
                disabled={app["booting"] or not app["snapshot"]}
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
            <NoPlanYet what="Decision Trace" planning={planning} disabled={app["booting"] or not app["snapshot"]} onRun={app["runPlan"]} />
        } else {
        <div className={"mx-auto w-full max-w-4xl transition-opacity " + ("pointer-events-none opacity-60" if planning else "")}>
            <DecisionTrace
                academic={plan.academic}
                finance={plan.finance}
                balance={plan.balance}
                coordinator={plan.coordinator}
                previous={app["previous"]}
            />
        </div>
        }}
    </div>;
}
