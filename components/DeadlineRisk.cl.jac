import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    Alert02Icon,
    AlertCircleIcon,
    CheckmarkCircle02Icon,
    FireIcon
}
import from .display { level_tone }


def risk_icon(level: str) -> any {
    if level == "LOW" {
        return CheckmarkCircle02Icon;
    }
    if level == "MEDIUM" {
        return AlertCircleIcon;
    }
    if level == "CRITICAL" {
        return FireIcon;
    }
    return Alert02Icon;
}


"""Risk/urgency pill. Always text + icon + colour, never colour alone."""
def:pub RiskBadge(level: str, suffix: str = "", className: str = "") -> JsxElement {
    shown = level or "N/A";
    return <span
        className={"inline-flex h-6 shrink-0 items-center gap-1 rounded-full border px-2.5 text-[11px] font-semibold tracking-wide whitespace-nowrap " + level_tone(level) + " " + className}
    >
        <HugeiconsIcon icon={risk_icon(level)} strokeWidth={2} className="size-3.5" />
        {shown + (" " + suffix if suffix else "")}
    </span>;
}


"""Shows "HIGH -> LOW" after a replan; just the badge when unchanged."""
def:pub LevelChange(before: str, after: str, suffix: str = "") -> JsxElement {
    if not before or before == after {
        return <RiskBadge level={after} suffix={suffix} />;
    }
    return <span className="inline-flex items-center gap-1.5">
        <span className="text-[11px] font-semibold text-muted-foreground line-through">{before}</span>
        <span aria-hidden="true" className="text-muted-foreground">→</span>
        <RiskBadge level={after} suffix={suffix} />
    </span>;
}


"""Deadline-risk warning surfaced from the Academic Agent's deterministic risk level."""
def:pub DeadlineRiskAlert(level: str, summary: str) -> JsxElement {
    if level != "HIGH" and level != "CRITICAL" {
        return <span className="hidden" />;
    }
    critical = level == "CRITICAL";
    tone = "border-risk-critical/40 bg-risk-critical/10" if critical else "border-risk-high/30 bg-risk-high/5";
    return <div role="alert" className={"flex items-start gap-3 rounded-xl border px-4 py-3 " + tone}>
        <span className={"mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-lg " + ("bg-risk-critical text-white" if critical else "bg-risk-high/15 text-risk-high")}>
            <HugeiconsIcon icon={FireIcon if critical else Alert02Icon} strokeWidth={2} className="size-4" />
        </span>
        <div className="flex min-w-0 flex-col gap-0.5">
            <div className="flex flex-wrap items-center gap-2 text-sm font-semibold">
                Deadline risk
                <RiskBadge level={level} />
            </div>
            <p className="text-sm text-muted-foreground">{summary}</p>
        </div>
    </div>;
}
