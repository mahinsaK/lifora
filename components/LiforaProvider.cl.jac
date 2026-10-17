"""Lifora app state shared by every page.

One provider owns the student snapshot, the latest plan and all server calls;
pages read it with `useLifora()` (see `jac guide jac-cl-organization`, context).
"""

import from react { createContext, useContext }
import from "sonner" { toast }
import from .display { PlanStep, parse_plan, level_of, fmt_clock, next_quarter_minutes }
sv import from ..services.state { initialize_demo_state, update_available_time }
sv import from ..services.tasks { update_task_progress }
sv import from ..services.finance { add_expense }
sv import from ..services.snapshot { StudentSnapshot, get_student_snapshot }
sv import from ..services.planning { plan_student }
sv import from ..agents.types { PlanningResponse }


glob LiforaContext: any = createContext(None);


"""The RPC body key comes from the argument's name, so it must be `snapshot`."""
async def request_plan(snapshot: StudentSnapshot) -> PlanningResponse {
    return await plan_student(snapshot);
}


def now_label -> str {
    now = new(Date);  # jac:ignore[W2001]
    return fmt_clock(int(now.getHours() * 60 + now.getMinutes()));
}


def error_text(err: any) -> str {
    message = err.message if err and err.message else "";
    return message or "Something went wrong. Please try again.";
}


"""Read the shared Lifora state. Keys are documented in LiforaProvider's value."""
def:pub useLifora -> any {
    return useContext(LiforaContext);
}


def:pub LiforaProvider(children: any = None) -> JsxElement {
    has snapshot: StudentSnapshot | None = None,
        booting: bool = True,
        bootError: str = "",
        plan: PlanningResponse | None = None,
        planning: bool = False,
        planError: str = "",
        stale: bool = False,
        lastRun: str = "",
        planStart: int = 0,
        previous: dict[str, str] = {},
        changedTaskId: str = "",
        previousProgress: float = 0.0,
        previousRemaining: float = -1.0,
        previousHours: float = -1.0,
        dialog: str = "",
        saving: bool = False;

    async can with entry {
        await load_state();
    }

    async def load_state -> None {
        booting = True;
        bootError = "";
        try {
            await initialize_demo_state();
            snapshot = await get_student_snapshot();
        } except Exception as err {
            bootError = "We couldn't load your student data.";
        }
        booting = False;
    }

    async def plan_for(current: StudentSnapshot) -> None {
        older = plan;
        planning = True;
        planError = "";
        try {
            result = await request_plan(current);
            if older {
                previous = {
                    "academic": level_of(older.academic.urgency),
                    "academicRisk": level_of(older.academic.risk_level),
                    "finance": level_of(older.finance.urgency),
                    "balance": level_of(older.balance.urgency),
                    "action": older.coordinator.next_action
                };
            }
            plan = result;
            planStart = next_quarter_minutes();
            lastRun = now_label();
            stale = False;
        } except Exception as err {
            planError = "Lifora's reasoning is unavailable right now.";
        }
        planning = False;
    }

    async def run_plan -> None {
        if snapshot {
            await plan_for(snapshot);
        }
    }

    """After any saved change: refresh state, then replan if a plan exists."""
    async def after_change(message: str) -> None {
        fresh = await get_student_snapshot();
        snapshot = fresh;
        dialog = "";
        toast.success(message, {"description": "Replanning with your new situation…" if plan else "Ask Lifora when you're ready."});
        if plan {
            stale = True;
            await plan_for(fresh);
        }
    }

    async def save_progress(task_id: str, progress: float) -> None {
        saving = True;
        before = 0.0;
        if snapshot {
            for t in snapshot.academic_tasks {
                if t.id == task_id {
                    before = t.progress;
                }
            }
        }
        try {
            await update_task_progress(task_id, progress);
            changedTaskId = task_id;
            previousProgress = before;
            saving = False;
            await after_change("Progress updated to " + str(int(round(progress))) + "%");
        } except Exception as err {
            saving = False;
            toast.error("Couldn't update progress", {"description": error_text(err)});
        }
    }

    async def save_expense(amount: float, description: str) -> None {
        saving = True;
        before = snapshot.finance.remaining_budget if snapshot else -1.0;
        expense_id = "exp-" + str(Date.now());  # jac:ignore[W2001]
        try {
            await add_expense(expense_id, amount, description);
            previousRemaining = before;
            saving = False;
            await after_change("Expense added");
        } except Exception as err {
            saving = False;
            toast.error("Couldn't add the expense", {"description": error_text(err)});
        }
    }

    async def save_time(available_hours_today: float) -> None {
        saving = True;
        before = snapshot.available_time.available_hours_today if snapshot else -1.0;
        try {
            await update_available_time(available_hours_today);
            previousHours = before;
            saving = False;
            await after_change("Available time updated");
        } except Exception as err {
            saving = False;
            toast.error("Couldn't update your time", {"description": error_text(err)});
        }
    }

    def set_dialog(name: str) {
        if name or not saving {
            dialog = name;
        }
    }

    steps: list[PlanStep] = parse_plan(plan.coordinator.daily_plan) if plan else [];
    focus_hours = 0.0;
    for step in steps {
        if step.kind != "break" {
            focus_hours = focus_hours + step.hours;
        }
    }

    value = {
        "snapshot": snapshot,
        "booting": booting,
        "bootError": bootError,
        "plan": plan,
        "planning": planning,
        "planError": planError,
        "stale": stale,
        "lastRun": lastRun,
        "planStart": planStart,
        "steps": steps,
        "focusHours": focus_hours,
        "previous": previous,
        "changedTaskId": changedTaskId,
        "previousProgress": previousProgress,
        "previousRemaining": previousRemaining,
        "previousHours": previousHours,
        "dialog": dialog,
        "saving": saving,
        "reload": load_state,
        "runPlan": run_plan,
        "clearPlanError": lambda { planError = ""; },
        "saveProgress": save_progress,
        "saveExpense": save_expense,
        "saveTime": save_time,
        "setDialog": set_dialog
    };

    return <LiforaContext.Provider value={value}>{children}</LiforaContext.Provider>;
}
