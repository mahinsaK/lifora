import from ..components.PageParts { NoPlanYet, PageHeader }
import from ..components.WhatIfPanel { WhatIfPanel }
import from ..components.LiforaProvider { useLifora }
sv import from ..services.simulation { simulate_plan }
sv import from ..services.snapshot { StudentSnapshot }
sv import from ..agents.types { PlanningResponse }

"""/whatif - compare the current plan with a non-persistent scenario."""
def:pub WhatIfPage -> JsxPage {
    app = useLifora();
    has scenario: str = "",
        running: bool = False,
        failed: bool = False,
        simulated: PlanningResponse | None = None,
        simulatedSnapshot: StudentSnapshot | None = None;

    async def pick(nextScenario: str) {
        scenario = nextScenario;
        running = True;
        failed = False;
        simulated = None;
        simulatedSnapshot = None;
        try {
            result = await simulate_plan(nextScenario);
            simulated = result.plan;
            simulatedSnapshot = result.snapshot;
        } except Exception {
            failed = True;
        }
        running = False;
    }

    def reset {
        scenario = "";
        failed = False;
        simulated = None;
        simulatedSnapshot = None;
    }

    return <div className="flex flex-col gap-6">
        <PageHeader
            eyebrow="Explore safely"
            title="What-If Simulator"
            description="Try a scenario against the same agents. Your real graph data is never changed."
        />
        {if not app["plan"] or not app["snapshot"] {
            <NoPlanYet what="What-If comparison" planning={app["planning"]} disabled={app["booting"] or not app["snapshot"]} onRun={app["runPlan"]} />
        } else {
            <WhatIfPanel
                scenario={scenario}
                running={running}
                failed={failed}
                current={app["plan"]}
                currentSnapshot={app["snapshot"]}
                simulated={simulated}
                simulatedSnapshot={simulatedSnapshot}
                onPick={pick}
                onReset={reset}
            />
        }}
    </div>;
}
