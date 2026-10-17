import from "@jac/runtime" { Link }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    HourglassIcon,
    Wallet01Icon,
    CheckmarkCircle02Icon,
    InformationCircleIcon,
    ArrowRight01Icon
}
import from ..components.PageParts { PageHeader }


glob SCENARIOS: list[dict[str, any]] = [
    {"icon": HourglassIcon, "title": "I have 2 fewer hours tonight", "detail": "See how a tighter evening changes academic risk and the plan."},
    {"icon": Wallet01Icon, "title": "I unexpectedly spend Rs. 2,000", "detail": "See how the Finance Agent reacts before you actually spend it."},
    {"icon": CheckmarkCircle02Icon, "title": "I finish the ML assignment early", "detail": "See what Lifora would recommend next once it is done."}
];


"""/what-if - stretch feature. Runs the same agents on a copy of your data.

Waiting on a server-side simulation endpoint (agents team): shared objects like
StudentSnapshot can't be built in the browser, so the copy must be made on the
server. The comparison UI lives in components/WhatIfPanel.cl.jac.
"""
def:pub WhatIfPage -> JsxPage {
    return <div className="flex flex-col gap-6">
        <PageHeader
            eyebrow="Stretch"
            title="What-If Simulator"
            description="Try a scenario and compare it with your current plan. Your real data is never changed."
        />

        <div className="flex items-start gap-3 rounded-xl border border-dashed border-primary/30 bg-primary/5 px-4 py-3 text-sm">
            <HugeiconsIcon icon={InformationCircleIcon} strokeWidth={2} className="mt-0.5 size-4 shrink-0 text-primary" />
            <p>
                <span className="font-semibold">Coming soon. </span>
                <span className="text-muted-foreground">Simulations run the same Academic, Finance and Balance agents on a copy of your data. This switches on once the simulation service is connected.</span>
            </p>
        </div>

        <div className="grid gap-4 md:grid-cols-3">
            {for s in SCENARIOS {
                <article key={s["title"]} aria-disabled="true" className="flex flex-col gap-3 rounded-xl border bg-card p-5 shadow-sm">
                    <span className="flex size-10 items-center justify-center rounded-xl bg-muted text-muted-foreground">
                        <HugeiconsIcon icon={s["icon"]} strokeWidth={2} className="size-5" />
                    </span>
                    <h2 className="text-base font-semibold leading-snug">{s["title"]}</h2>
                    <p className="text-sm text-muted-foreground">{s["detail"]}</p>
                    <span className="mt-auto w-fit rounded-full bg-muted px-2.5 py-1 text-xs font-medium text-muted-foreground">Not available yet</span>
                </article>
            }}
        </div>

        <Link to="/update" className="group flex items-center justify-between gap-3 rounded-xl border bg-card p-4 text-sm shadow-sm transition-colors hover:border-primary/40 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50">
            <span><span className="font-semibold">Want to see a real change now? </span><span className="text-muted-foreground">Update your progress, expenses or time and Lifora replans.</span></span>
            <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="size-4 shrink-0 text-muted-foreground transition-transform group-hover:translate-x-0.5" />
        </Link>
    </div>;
}
