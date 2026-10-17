import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    SparklesIcon,
    BookOpen01Icon,
    Wallet01Icon,
    HourglassIcon,
    AiNetworkIcon,
    ArrowRight01Icon,
    AlertCircleIcon,
    RefreshIcon,
    Cancel01Icon
}
import from .ui.button { Button }
import from .ui.skeleton { Skeleton }
import from .ui.spinner { Spinner }


def AgentChip(label: str, icon: any, tone: str, busy: bool) -> JsxElement {
    return <span className={"inline-flex items-center gap-1.5 rounded-full border bg-card px-3 py-1.5 text-xs font-medium " + tone + (" motion-safe:animate-pulse" if busy else "")}>
        <HugeiconsIcon icon={icon} strokeWidth={2} className="size-3.5" />
        {label}
    </span>;
}


def AgentFlow(busy: bool) -> JsxElement {
    return <div className="flex flex-wrap items-center justify-center gap-2">
        <AgentChip label="Academic · deadlines" icon={BookOpen01Icon} tone="text-agent-academic" busy={busy} />
        <AgentChip label="Finance · spending" icon={Wallet01Icon} tone="text-agent-finance" busy={busy} />
        <AgentChip label="Balance · time" icon={HourglassIcon} tone="text-agent-balance" busy={busy} />
        <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="size-4 text-muted-foreground" />
        <span className="inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-3 py-1.5 text-xs font-semibold text-primary">
            <HugeiconsIcon icon={AiNetworkIcon} strokeWidth={2} className="size-3.5" />
            Coordinator
        </span>
    </div>;
}


"""Before the first run: explains what will appear and how."""
def:pub EmptyResult(onRun: Callable[[], None], disabled: bool) -> JsxElement {
    def handle_run(e: MouseEvent) {
        onRun();
    }
    return <section className="flex flex-col items-center gap-5 rounded-2xl border-2 border-dashed border-primary/20 bg-card/60 px-6 py-12 text-center">
        <span className="flex size-14 items-center justify-center rounded-full bg-primary/10 text-primary">
            <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-7" />
        </span>
        <div className="flex max-w-md flex-col gap-1.5">
            <h2 className="text-lg font-semibold">Ask Lifora what to do next</h2>
            <p className="text-sm text-muted-foreground">Your Best Next Action, Daily Plan and Decision Trace will appear here.</p>
        </div>
        <AgentFlow busy={False} />
        <Button variant="outline" onClick={handle_run} disabled={disabled} className="gap-2">
            <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-4" />
            Get my next step
        </Button>
    </section>;
}


"""While the planning pipeline runs. Honest progress - no fake per-agent ticks."""
def:pub ThinkingResult -> JsxElement {
    return <section aria-live="polite" aria-busy="true" className="flex flex-col gap-4">
        <div className="flex flex-col items-center gap-4 rounded-2xl border bg-card px-6 py-6 shadow-sm">
            <p className="flex items-center gap-2 text-sm font-medium">
                <Spinner className="size-4 text-primary" />
                Specialist agents are analysing your situation…
            </p>
            <AgentFlow busy={True} />
            <div className="h-1 w-full max-w-md overflow-hidden rounded-full bg-muted">
                <div className="h-full w-1/3 rounded-full bg-primary motion-safe:animate-[lifora-slide_1.4s_ease-in-out_infinite]" />
            </div>
        </div>
        <div className="flex flex-col gap-4 rounded-2xl border bg-card p-6 shadow-sm">
            <Skeleton className="h-3 w-32" />
            <Skeleton className="h-8 w-3/4" />
            <Skeleton className="h-4 w-1/2" />
        </div>
        <div className="grid gap-4 lg:grid-cols-12">
            <div className="flex flex-col gap-3 rounded-xl border bg-card p-6 shadow-sm lg:col-span-5">
                <Skeleton className="h-5 w-28" />
                <Skeleton className="h-12 w-full" />
                <Skeleton className="h-12 w-full" />
                <Skeleton className="h-12 w-full" />
            </div>
            <div className="flex flex-col gap-3 rounded-xl border bg-card p-6 shadow-sm lg:col-span-7">
                <Skeleton className="h-5 w-36" />
                <Skeleton className="h-16 w-full" />
                <Skeleton className="h-16 w-full" />
                <Skeleton className="h-16 w-full" />
            </div>
        </div>
    </section>;
}


"""Planning failed: keep everything visible, offer a retry."""
def:pub ErrorBanner(
    message: str,
    hasPrevious: bool,
    onRetry: Callable[[], None],
    onDismiss: Callable[[], None]
) -> JsxElement {
    def handle_retry(e: MouseEvent) {
        onRetry();
    }
    def handle_dismiss(e: MouseEvent) {
        onDismiss();
    }
    return <div role="alert" className="flex flex-col gap-3 rounded-xl border border-destructive/30 bg-destructive/5 px-4 py-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-start gap-3">
            <HugeiconsIcon icon={AlertCircleIcon} strokeWidth={2} className="mt-0.5 size-5 shrink-0 text-destructive" />
            <div className="flex flex-col gap-0.5">
                <p className="text-sm font-semibold">{message}</p>
                <p className="text-sm text-muted-foreground">
                    {"Your data is safe. Showing your last plan." if hasPrevious else "Your data is safe. Please try again in a moment."}
                </p>
            </div>
        </div>
        <div className="flex shrink-0 gap-2">
            <Button size="sm" onClick={handle_retry} className="gap-1.5">
                <HugeiconsIcon icon={RefreshIcon} strokeWidth={2} className="size-3.5" />
                Try again
            </Button>
            <Button size="sm" variant="ghost" onClick={handle_dismiss} aria-label="Dismiss">
                <HugeiconsIcon icon={Cancel01Icon} strokeWidth={2} className="size-3.5" />
            </Button>
        </div>
    </div>;
}
