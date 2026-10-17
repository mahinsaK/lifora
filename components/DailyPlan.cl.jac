import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Calendar03Icon, Coffee01Icon, Target02Icon }
import from .display { PlanStep, fmt_clock, fmt_hours }


def:pub DailyPlan(steps: list[PlanStep], startMinutes: int) -> JsxElement {
    focus = 0.0;
    for step in steps {
        if step.kind != "break" {
            focus = focus + step.hours;
        }
    }
    starts: list[int] = [];
    cursor = startMinutes;
    for step in steps {
        starts = starts + [cursor];
        cursor = cursor + int(round(step.hours * 60));
    }

    return <section aria-labelledby="daily-plan" className="flex flex-col gap-5 rounded-xl border bg-card p-5 shadow-sm sm:p-6">
        <header className="flex items-start justify-between gap-3">
            <div className="flex flex-col gap-0.5">
                <h2 id="daily-plan" className="text-lg font-semibold tracking-tight">Daily Plan</h2>
                <p className="text-sm text-muted-foreground">Tonight, in order</p>
            </div>
            <span className="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-wide text-primary">
                <HugeiconsIcon icon={Calendar03Icon} strokeWidth={2} className="size-3.5" />
                Today
            </span>
        </header>
        {if len(steps) == 0 {
            <p className="rounded-lg border border-dashed px-4 py-6 text-center text-sm text-muted-foreground">
                No focus blocks needed right now.
            </p>
            skip;
        }}
        <ol className="relative flex flex-col">
            {for (i, step) in enumerate(steps) {
                <PlanRow
                    key={str(i)}
                    step={step}
                    start={starts[i]}
                    last={i == len(steps) - 1}
                />
            }}
        </ol>
        <footer className="mt-auto flex items-center justify-between border-t pt-4 text-sm">
            <span className="text-muted-foreground">Times are suggestions from now</span>
            <span className="font-semibold tabular-nums">{fmt_hours(focus) + " focus"}</span>
        </footer>
    </section>;
}


def PlanRow(step: PlanStep, start: int, last: bool) -> JsxElement {
    is_break = step.kind == "break";
    end = start + int(round(step.hours * 60));
    has_time = step.hours > 0;
    dot = "bg-muted-foreground/40" if is_break else "bg-primary ring-4 ring-primary/15";
    return <li className="relative flex gap-4 pb-5 last:pb-0">
        {not last and <span aria-hidden="true" className="absolute top-4 bottom-0 left-[7px] w-px bg-border" />}
        <span aria-hidden="true" className={"relative z-10 mt-1.5 size-3.5 shrink-0 rounded-full border-2 border-card " + dot} />
        <div className="flex min-w-0 flex-1 flex-wrap items-start justify-between gap-x-4 gap-y-1">
            <div className="flex min-w-0 flex-col gap-0.5">
                <span className={"flex items-center gap-1.5 text-sm " + ("italic text-muted-foreground" if is_break else "font-semibold")}>
                    <HugeiconsIcon icon={Coffee01Icon if is_break else Target02Icon} strokeWidth={2} className="size-3.5 shrink-0" />
                    {step.title}
                </span>
                {has_time and <span className="text-xs text-muted-foreground">{fmt_hours(step.hours) + (" break" if is_break else " focused")}</span>}
            </div>
            <div className="flex flex-col items-end gap-1">
                {has_time and <span className="text-sm font-medium tabular-nums">{fmt_clock(start) + " – " + fmt_clock(end)}</span>}
                <span className={"rounded-md px-1.5 py-0.5 text-[11px] font-semibold " + ("bg-muted text-muted-foreground" if is_break else "bg-primary/10 text-primary")}>
                    {"Rest" if is_break else "Focus"}
                </span>
            </div>
        </div>
    </li>;
}
