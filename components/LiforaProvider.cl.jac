"""Lifora app state shared by every page.

One provider owns the student snapshot, the latest plan and all server calls;
pages read it with `useLifora()` (see `jac guide jac-cl-organization`, context).
"""

import from react { createContext, useContext }
import from "sonner" { toast }
import from .display { PlanStep, parse_plan, level_of, fmt_clock, next_quarter_minutes }
sv import from ..services.state { initialize_demo_state, update_available_time }
sv import from ..services.tasks { add_academic_task, complete_academic_task, update_academic_task, update_task_progress }
sv import from ..services.finance { add_expense, add_income, get_transactions, reverse_transaction }
sv import from ..services.state { TransactionView }
sv import from ..services.state { GoalView }
sv import from ..services.student_management { add_goal, get_goals, remove_goal, update_profile }
sv import from ..services.snapshot { StudentSnapshot, get_student_snapshot }
sv import from ..services.planning { WhatIfResponse, plan_student, simulate_plan }
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
        saving: bool = False,
        whatIfScenario: str = "",
        whatIfRunning: bool = False,
        whatIfFailed: bool = False,
        simulatedPlan: PlanningResponse | None = None,
        simulatedSnapshot: StudentSnapshot | None = None,
        transactions: list[TransactionView] = [],
        goals: list[GoalView] = [];

    async can with entry {
        await load_state();
    }

    async def load_state -> None {
        booting = True;
        bootError = "";
        try {
            await initialize_demo_state();
            snapshot = await get_student_snapshot();
            transactions = await get_transactions();
            goals = await get_goals();
        } except Exception as err {
            bootError = "We couldn't load your student data.";
        }
        booting = False;
    }

    async def plan_for(
        current: StudentSnapshot,
        confirmation: str = ""
    ) -> None {
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
            reset_what_if();
            if confirmation {
                toast.success(
                    confirmation,
                    {
                        "description": "Your latest coursework, spending, and focus time were checked."
                    }
                );
            }
        } except Exception as err {
            planError = "Lifora's reasoning is unavailable right now.";
            if confirmation {
                toast.error(
                    "Couldn't refresh your decision",
                    {"description": error_text(err)}
                );
            }
        }
        planning = False;
    }

    async def run_plan -> None {
        if not snapshot {
            return;
        }

        was_rerun = plan is not None;
        planning = True;
        planError = "";
        try {
            # A manual rerun must use persisted data, not a possibly stale
            # browser snapshot. The extra request also makes progress visible.
            fresh = await get_student_snapshot();
            snapshot = fresh;
            await plan_for(
                fresh,
                "Decision refreshed" if was_rerun else "Decision ready"
            );
        } except Exception as err {
            planning = False;
            planError = "We couldn't refresh your latest student data.";
            toast.error(
                "Couldn't refresh your decision",
                {"description": error_text(err)}
            );
        }
    }

    """After any saved change: refresh state, then replan if a plan exists."""
    async def after_change(message: str) -> None {
        fresh = await get_student_snapshot();
        snapshot = fresh;
        transactions = await get_transactions();
        goals = await get_goals();
        dialog = "";
        toast.success(
            message,
            {
                "description": "Replanning with your new situation…"
                    if plan
                    else "Ask Lifora when you're ready."
            }
        );
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
            await after_change(
                "Progress updated to " + str(int(round(progress))) + "%"
            );
        } except Exception as err {
            saving = False;
            toast.error("Couldn't update progress", {"description": error_text(err)});
        }
    }

    async def save_task(
        title: str,
        deadline: str,
        progress: float,
        estimated_remaining_hours: float,
        importance: int
    ) -> None {
        saving = True;
        task_id = "task-" + str(Date.now());  # jac:ignore[W2001]
        try {
            await add_academic_task(
                task_id,
                title,
                deadline,
                progress,
                estimated_remaining_hours,
                importance
            );
            changedTaskId = task_id;
            previousProgress = progress;
            saving = False;
            await after_change("Task added");
        } except Exception as err {
            saving = False;
            toast.error("Couldn't add the task", {"description": error_text(err)});
        }
    }

    async def save_task_details(
        task_id: str,
        title: str,
        deadline: str,
        progress: float,
        estimated_remaining_hours: float,
        importance: int
    ) -> None {
        saving = True;
        try {
            await update_academic_task(
                task_id, title, deadline, progress, estimated_remaining_hours, importance
            );
            changedTaskId = task_id;
            saving = False;
            await after_change("Task updated");
        } except Exception as err {
            saving = False;
            toast.error("Couldn't update the task", {"description": error_text(err)});
        }
    }

    async def complete_task(task_id: str) -> None {
        saving = True;
        try {
            await complete_academic_task(task_id);
            changedTaskId = task_id;
            saving = False;
            await after_change("Task completed");
        } except Exception as err {
            saving = False;
            toast.error("Couldn't complete the task", {"description": error_text(err)});
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

    async def save_income(amount: float, description: str, received_on: str) -> None {
        saving = True;
        before = snapshot.finance.remaining_budget if snapshot else -1.0;
        transaction_id = "income-" + str(Date.now());  # jac:ignore[W2001]
        try {
            await add_income(transaction_id, amount, description, received_on);
            previousRemaining = before;
            saving = False;
            await after_change("Income added");
        } except Exception as err {
            saving = False;
            toast.error("Couldn't add the income", {"description": error_text(err)});
        }
    }

    async def reverse_financial_transaction(transaction_id: str, kind: str) -> None {
        saving = True;
        before = snapshot.finance.remaining_budget if snapshot else -1.0;
        try {
            await reverse_transaction(transaction_id, kind);
            previousRemaining = before;
            saving = False;
            await after_change("Transaction reversed");
        } except Exception as err {
            saving = False;
            toast.error("Couldn't reverse the transaction", {"description": error_text(err)});
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

    async def save_profile(name: str, life_stage: str) -> None {
        saving = True;
        try {
            await update_profile(name, life_stage);
            saving = False;
            await after_change("Profile updated");
        } except Exception as err {
            saving = False;
            toast.error("Couldn't update the profile", {"description": error_text(err)});
        }
    }

    async def save_goal(title: str) -> None {
        saving = True;
        try {
            await add_goal("goal-" + str(Date.now()), title);  # jac:ignore[W2001]
            saving = False;
            await after_change("Goal added");
        } except Exception as err {
            saving = False;
            toast.error("Couldn't add the goal", {"description": error_text(err)});
        }
    }

    async def delete_goal(goal_id: str) -> None {
        saving = True;
        try {
            await remove_goal(goal_id);
            saving = False;
            await after_change("Goal removed");
        } except Exception as err {
            saving = False;
            toast.error("Couldn't remove the goal", {"description": error_text(err)});
        }
    }

    def set_dialog(name: str) {
        if name or not saving {
            dialog = name;
        }
    }

    def reset_what_if -> None {
        whatIfScenario = "";
        whatIfRunning = False;
        whatIfFailed = False;
        simulatedPlan = None;
        simulatedSnapshot = None;
    }

    async def run_what_if(scenario: str) -> None {
        whatIfScenario = scenario;
        whatIfRunning = True;
        whatIfFailed = False;
        simulatedPlan = None;
        simulatedSnapshot = None;
        try {
            result: WhatIfResponse = await simulate_plan(scenario);
            simulatedPlan = result.planning;
            simulatedSnapshot = result.snapshot;
        } except Exception as err {
            whatIfFailed = True;
        }
        whatIfRunning = False;
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
        "whatIfScenario": whatIfScenario,
        "whatIfRunning": whatIfRunning,
        "whatIfFailed": whatIfFailed,
        "simulatedPlan": simulatedPlan,
        "simulatedSnapshot": simulatedSnapshot,
        "transactions": transactions,
        "goals": goals,
        "reload": load_state,
        "runPlan": run_plan,
        "clearPlanError": lambda { planError = ""; },
        "saveProgress": save_progress,
        "saveTask": save_task,
        "saveTaskDetails": save_task_details,
        "completeTask": complete_task,
        "saveExpense": save_expense,
        "saveIncome": save_income,
        "reverseTransaction": reverse_financial_transaction,
        "saveTime": save_time,
        "saveProfile": save_profile,
        "saveGoal": save_goal,
        "deleteGoal": delete_goal,
        "setDialog": set_dialog,
        "runWhatIf": run_what_if,
        "resetWhatIf": reset_what_if
    };

    return <LiforaContext.Provider value={value}>{children}</LiforaContext.Provider>;
}
