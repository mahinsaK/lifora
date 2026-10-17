import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { SparklesIcon, Mortarboard01Icon }
import from .display { initials }


def:pub AppHeader(name: str, lifeStage: str) -> JsxElement {
    stage = "University student" if lifeStage.lower() == "university" else lifeStage;
    return <header className="sticky top-0 z-30 border-b bg-background/85 backdrop-blur supports-[backdrop-filter]:bg-background/70">
        <div className="mx-auto flex h-16 w-full max-w-6xl items-center justify-between gap-4 px-4 sm:px-6">
            <div className="flex items-center gap-3">
                <div className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm">
                    <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-5" />
                </div>
                <div className="flex flex-col leading-tight">
                    <span className="text-base font-semibold tracking-tight">Lifora</span>
                    <span className="text-xs text-muted-foreground">University Mode</span>
                </div>
            </div>
            <div className="flex items-center gap-3">
                <span className="hidden items-center gap-1.5 rounded-full border bg-card px-3 py-1 text-xs font-medium text-muted-foreground sm:inline-flex">
                    <HugeiconsIcon icon={Mortarboard01Icon} strokeWidth={2} className="size-3.5 text-primary" />
                    University Mode
                </span>
                <div className="flex items-center gap-2.5">
                    <div className="hidden text-right leading-tight sm:block">
                        <div className="text-sm font-medium">{name}</div>
                        <div className="text-xs text-muted-foreground">{stage}</div>
                    </div>
                    <div
                        aria-label={name}
                        className="flex size-9 items-center justify-center rounded-full bg-accent text-sm font-semibold text-accent-foreground ring-1 ring-primary/20"
                    >
                        {initials(name)}
                    </div>
                </div>
            </div>
        </div>
    </header>;
}
