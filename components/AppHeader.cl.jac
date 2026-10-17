import from "@jac/runtime" { Link, useLocation }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    SparklesIcon,
    Home01Icon,
    Target02Icon,
    Edit02Icon,
    SlidersHorizontalIcon
}
import from .display { initials }


glob NAV_ITEMS: list[dict[str, any]] = [
    {"to": "/", "label": "Overview", "icon": Home01Icon},
    {"to": "/plan", "label": "My Plan", "icon": Target02Icon},
    {"to": "/update", "label": "Update", "icon": Edit02Icon},
    {"to": "/whatif", "label": "What-If", "icon": SlidersHorizontalIcon}
];


def NavLink(item: dict[str, any], active: bool, alert: bool, compact: bool) -> JsxElement {
    base = "relative inline-flex shrink-0 items-center gap-1.5 rounded-lg font-medium transition-colors focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 ";
    size = "px-3 py-2 text-sm" if not compact else "px-3 py-1.5 text-[13px]";
    tone = "bg-primary/10 text-primary" if active else "text-muted-foreground hover:bg-muted hover:text-foreground";
    return <Link
        to={item["to"]}
        aria-current={"page" if active else None}
        className={base + size + " " + tone}
    >
        <HugeiconsIcon icon={item["icon"]} strokeWidth={2} className="size-4" />
        {item["label"]}
        {alert and <span aria-label="out of date" className="size-1.5 rounded-full bg-primary" />}
    </Link>;
}


def:pub AppHeader(name: str, lifeStage: str, planStale: bool) -> JsxElement {
    path = useLocation().pathname;
    stage = "University student" if lifeStage.lower() == "university" else lifeStage;
    return <header className="sticky top-0 z-30 border-b bg-background/85 backdrop-blur supports-[backdrop-filter]:bg-background/70">
        <div className="mx-auto flex h-16 w-full max-w-6xl items-center justify-between gap-4 px-4 sm:px-6">
            <Link to="/" className="flex items-center gap-3 rounded-lg focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50">
                <span className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm">
                    <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-5" />
                </span>
                <span className="flex flex-col leading-tight">
                    <span className="text-base font-semibold tracking-tight">Lifora</span>
                    <span className="text-xs text-muted-foreground">University Mode</span>
                </span>
            </Link>

            <nav aria-label="Main" className="hidden items-center gap-1 lg:flex">
                {for item in NAV_ITEMS {
                    <NavLink
                        key={item["to"]}
                        item={item}
                        active={path == item["to"]}
                        alert={planStale and item["to"] == "/plan"}
                        compact={False}
                    />
                }}
            </nav>

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

        <nav aria-label="Main" className="border-t lg:hidden">
            <div className="mx-auto flex w-full max-w-6xl gap-1 overflow-x-auto px-3 py-2 [scrollbar-width:none]">
                {for item in NAV_ITEMS {
                    <NavLink
                        key={item["to"]}
                        item={item}
                        active={path == item["to"]}
                        alert={planStale and item["to"] == "/plan"}
                        compact={True}
                    />
                }}
            </div>
        </nav>
    </header>;
}
