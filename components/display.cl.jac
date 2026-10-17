"""Display helpers shared by the Lifora dashboard components.

Pure formatting only - no planning or scheduling decisions live here.
"""

obj PlanStep {
    has kind: str,
        title: str,
        hours: float,
        raw: str;
}

glob DAY_MS: int = 86400000;


"""Normalise an enum or string level ("UrgencyLevel.HIGH" / "HIGH") to "HIGH"."""
def:pub level_of(value: any) -> str {
    text = str(value) if value else "";
    parts = text.split(".");
    return parts[len(parts) - 1].strip().upper();
}


def:pub level_rank(level: str) -> int {
    ranks = {"LOW": 1, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4};
    return ranks[level] or 0;
}


def:pub fmt_money(amount: float) -> str {
    whole = int(round(amount));
    sign = "-" if whole < 0 else "";
    digits = str(abs(whole));
    grouped = "";
    while len(digits) > 3 {
        grouped = "," + digits[len(digits) - 3:] + grouped;
        digits = digits[:len(digits) - 3];
    }
    return "Rs. " + sign + digits + grouped;
}


def:pub fmt_hours(hours: float) -> str {
    total = int(round(hours * 60));
    whole_hours = int(total / 60);
    minutes = total - whole_hours * 60;
    if whole_hours == 0 {
        return str(minutes) + "m";
    }
    if minutes == 0 {
        return str(whole_hours) + "h";
    }
    return str(whole_hours) + "h " + str(minutes) + "m";
}


def:pub fmt_clock(minutes_of_day: int) -> str {
    minutes = minutes_of_day % (24 * 60);
    hour24 = int(minutes / 60);
    minute = minutes - hour24 * 60;
    suffix = "PM" if hour24 >= 12 else "AM";
    hour12 = hour24 % 12;
    hour12 = 12 if hour12 == 0 else hour12;
    pad = "0" if minute < 10 else "";
    return str(hour12) + ":" + pad + str(minute) + " " + suffix;
}


"""Minutes since midnight, rounded up to the next quarter hour."""
def:pub next_quarter_minutes -> int {
    now = new(Date);  # jac:ignore[W2001]
    minutes = now.getHours() * 60 + now.getMinutes();
    return int((minutes + 14) / 15) * 15;
}


"""Whole days from today until an ISO date (YYYY-MM-DD); negative when overdue."""
def:pub days_until(deadline: str) -> int {
    parts = deadline.split("-");
    if len(parts) < 3 {
        return 0;
    }
    due = new(Date, int(parts[0]), int(parts[1]) - 1, int(parts[2]));  # jac:ignore[W2001]
    now = new(Date);  # jac:ignore[W2001]
    today = new(Date, now.getFullYear(), now.getMonth(), now.getDate());  # jac:ignore[W2001]
    return int(round((due.getTime() - today.getTime()) / DAY_MS));
}


def:pub deadline_label(deadline: str) -> str {
    days = days_until(deadline);
    if days < 0 {
        return "Overdue";
    }
    if days == 0 {
        return "Due today";
    }
    if days == 1 {
        return "Due tomorrow";
    }
    return "Due in " + str(days) + " days";
}


def:pub initials(name: str) -> str {
    letters = "";
    for word in name.strip().split(" ") {
        if len(word) > 0 and len(letters) < 2 {
            letters = letters + word[0].upper();
        }
    }
    return letters or "?";
}


"""Soft badge classes for a risk or urgency level."""
def:pub level_tone(level: str) -> str {
    if level == "LOW" {
        return "border-risk-low/25 bg-risk-low/10 text-risk-low";
    }
    if level == "MEDIUM" {
        return "border-risk-medium/30 bg-risk-medium/10 text-risk-medium";
    }
    if level == "HIGH" {
        return "border-risk-high/25 bg-risk-high/10 text-risk-high";
    }
    if level == "CRITICAL" {
        return "border-risk-critical bg-risk-critical text-white";
    }
    return "border-border bg-muted text-muted-foreground";
}


"""Turn Coordinator plan lines ("Focus block 1: 1.50 hours on X", "Break: 0.25 hours")
into display steps. Unknown formats are kept verbatim."""
def:pub parse_plan(items: list[str]) -> list[PlanStep] {
    steps: list[PlanStep] = [];
    for raw in items {
        text = raw.strip();
        label = text;
        rest = "";
        pieces = text.split(":");
        if len(pieces) > 1 {
            label = pieces[0].strip();
            rest = ":".join(pieces[1:]).strip();
        }
        kind = "break" if label.lower().startswith("break") else "focus";
        hours = 0.0;
        title = text;
        words = rest.split(" ");
        if len(words) >= 2 and words[1].lower().startswith("hour") {
            parsed = float(words[0]);
            hours = 0.0 if parsed != parsed else parsed;
            on_parts = rest.split(" on ");
            if kind == "break" {
                title = "Break";
            } elif len(on_parts) > 1 {
                title = " on ".join(on_parts[1:]).strip();
            } else {
                title = label;
            }
        }
        steps = steps + [PlanStep(kind=kind, title=title, hours=hours, raw=text)];
    }
    return steps;
}
