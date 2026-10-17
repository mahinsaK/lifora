import from ..components.PageParts { PageHeader, RunButton, NoPlanYet }
import from ..components.WhatIfPanel { WhatIfPanel }
import from ..components.LiforaProvider { useLifora }


"""/what-if - run the same agents on a non-persistent snapshot copy."""
def:pub WhatIfPage -> JsxPage {
    app = useLifora();
    snapshot = app["snapshot"];
    plan = app["plan"];
    planning: bool = app["planning"];

    return
        <div className="flex flex-col gap-6">
            <PageHeader
                eyebrow="Stretch"
                title="What-If Simulator"
                description="Try a scenario and compare it with your current plan. Your real data is never changed."
            >
                <RunButton
                    planning={planning}
                    hasPlan={plan is not None}
                    stale={app["stale"]}
                    disabled={app["booting"] or not snapshot}
                    onRun={app["runPlan"]}
                />
            </PageHeader>
            {if snapshot and plan {
                <WhatIfPanel
                    scenario={app["whatIfScenario"]}
                    running={app["whatIfRunning"]}
                    failed={app["whatIfFailed"]}
                    current={plan}
                    currentSnapshot={snapshot}
                    simulated={app["simulatedPlan"]}
                    simulatedSnapshot={app["simulatedSnapshot"]}
                    onPick={app["runWhatIf"]}
                    onReset={app["resetWhatIf"]}
                />
            } else {
                <NoPlanYet
                    what="What-If comparison"
                    planning={planning}
                    disabled={app["booting"] or not snapshot}
                    onRun={app["runPlan"]}
                />
            } }
        </div>;
}
