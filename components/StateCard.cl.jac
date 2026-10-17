import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { AiBrain01Icon }
import from .ui.button { Button }


"""Shared shell for the Academic / Finance / Available Time cards."""
def:pub StateCard(
    title: str,
    subtitle: str,
    icon: any,
    accent: str,
    actionLabel: str,
    actionIcon: any,
    onAction: Callable[[], None],
    actionDisabled: bool = False,
    children: any = None
) -> JsxElement {
    def handle_action(e: MouseEvent) {
        onAction();
    }
    return <article className="group/card relative flex flex-col gap-5 overflow-hidden rounded-xl border bg-card p-5 shadow-sm transition-shadow hover:shadow-md">
        <span aria-hidden="true" className={"absolute inset-y-0 left-0 w-1 " + accent} />
        <header className="flex items-start justify-between gap-3">
            <div className="flex items-center gap-3">
                <span className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary">
                    <HugeiconsIcon icon={icon} strokeWidth={2} className="size-5" />
                </span>
                <div className="flex flex-col">
                    <h2 className="text-base font-semibold leading-tight">{title}</h2>
                    <p className="text-xs text-muted-foreground">{subtitle}</p>
                </div>
            </div>
            <Button
                variant="outline"
                size="sm"
                onClick={handle_action}
                disabled={actionDisabled}
                className="h-8 shrink-0 gap-1.5"
            >
                <HugeiconsIcon icon={actionIcon} strokeWidth={2} className="size-3.5" />
                {actionLabel}
            </Button>
        </header>
        {children}
    </article>;
}


"""Footer line quoting one specialist agent; a quiet hint before the first run."""
def:pub AgentNote(agentName: str, text: str, tone: str) -> JsxElement {
    if not text {
        return <p className="mt-auto rounded-lg border border-dashed px-3 py-2.5 text-xs text-muted-foreground">
            {"Run Lifora to hear from the " + agentName + "."}
        </p>;
    }
    return <div className="mt-auto flex items-start gap-2 rounded-lg bg-muted/60 px-3 py-2.5 text-sm">
        <HugeiconsIcon icon={AiBrain01Icon} strokeWidth={2} className={"mt-0.5 size-4 shrink-0 " + tone} />
        <p className="leading-snug">
            <span className={"font-semibold " + tone}>{agentName + ": "}</span>
            {text}
        </p>
    </div>;
}


"""Small "was X" marker shown after a value changes."""
def:pub WasValue(previous: str) -> JsxElement {
    return <span className="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-[11px] font-medium text-primary">
        Updated
        <span className="font-normal text-muted-foreground line-through">{previous}</span>
    </span>;
}
