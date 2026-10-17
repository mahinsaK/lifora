import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    SparklesIcon,
    ArrowRight01Icon,
    Clock01Icon,
    InformationCircleIcon,
    RefreshIcon
}
import from .ui.button { Button }
import from .ui.spinner { Spinner }


def greeting -> str {
    hour = new(Date).getHours();  # jac:ignore[W2001]
    if hour < 12 {
        return "Good morning";
    }
    if hour < 18 {
        return "Good afternoon";
    }
    return "Good evening";
}


def:pub HeroPanel(
    name: str,
    thinking: bool,
    hasResult: bool,
    stale: bool,
    lastRun: str,
    disabled: bool,
    onRun: Callable[[], None]
) -> JsxElement {
    first_name = name.split(" ")[0] if name else "there";
    label = "Find My Next Step";
    if hasResult {
        label = "Update My Next Step" if stale else "Re-run Decision";
    }

    caption = <span className="inline-flex items-center gap-1.5">
        <HugeiconsIcon icon={InformationCircleIcon} strokeWidth={2} className="size-3.5" />
        Three specialists compare coursework, spending, and focus time. One coordinator chooses the next step.
    </span>;
    if thinking {
        caption = <span className="inline-flex items-center gap-1.5 text-primary">
            Comparing coursework pressure, spending room, and focus time…
        </span>;
    } elif stale {
        caption = <span className="inline-flex items-center gap-1.5 font-medium text-primary">
            <span className="size-1.5 rounded-full bg-primary motion-safe:animate-pulse" />
            Your situation changed. The plan below may be out of date.
        </span>;
    } elif hasResult and lastRun {
        caption = <span className="inline-flex items-center gap-1.5">
            <HugeiconsIcon icon={Clock01Icon} strokeWidth={2} className="size-3.5" />
            {"Last planned at " + lastRun}
        </span>;
    }

    def handle_run(e: MouseEvent) {
        onRun();
    }

    return <section className="relative overflow-hidden rounded-2xl border bg-card shadow-sm">
        <div aria-hidden="true" className="pointer-events-none absolute inset-y-0 left-0 w-2/3 bg-gradient-to-r from-primary/10 via-primary/[0.04] to-transparent" />
        <div className="relative flex flex-col gap-6 px-5 py-6 sm:px-8 sm:py-8 lg:flex-row lg:items-center lg:justify-between">
            <div className="flex max-w-2xl flex-col gap-2">
                <p className="text-sm font-medium text-primary">{greeting() + ", " + first_name}</p>
                <h1 className="text-balance text-2xl font-semibold leading-tight tracking-tight sm:text-3xl lg:text-4xl">
                    One clear next step for your whole student life.
                </h1>
                <p className="text-sm text-muted-foreground sm:text-base">Lifora weighs what is due, what you can afford, and how many focused hours you realistically have left today.</p>
            </div>
            <div className="flex flex-col gap-2 lg:items-end">
                <Button
                    size="lg"
                    onClick={handle_run}
                    disabled={thinking or disabled}
                    aria-busy={thinking}
                    className="h-12 w-full gap-2 px-6 text-base shadow-md shadow-primary/20 sm:w-auto"
                >
                    {thinking and <Spinner className="size-4" />}
                    {not thinking and <HugeiconsIcon icon={RefreshIcon if hasResult else SparklesIcon} strokeWidth={2} className="size-4" />}
                    {"Lifora is thinking…" if thinking else label}
                    {not thinking and not hasResult and <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="size-4" />}
                </Button>
                <p aria-live="polite" className="text-xs text-muted-foreground">{caption}</p>
            </div>
        </div>
    </section>;
}
