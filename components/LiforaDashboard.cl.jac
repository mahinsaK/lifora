"""Lifora dashboard - the stateful shell.

Owns all page state and server calls; every section below it is a stateless
component fed through props (see `jac guide jac-cl-organization`).
"""

import from "sonner" { toast }
import from .ui.sonner_toast { Toaster }
import from .ui.skeleton { Skeleton }
import from .ui.button { Button }
import from .AppHeader { AppHeader }
import from .HeroPanel { HeroPanel }
import from .AcademicCard { AcademicCard }
import from .FinanceCard { FinanceCard }
import from .BalanceCard { BalanceCard }
import from .NextAction { NextAction }
import from .DailyPlan { DailyPlan }
import from .DecisionTrace { DecisionTrace }
import from .ResultStates { EmptyResult, ThinkingResult, ErrorBanner }
import from .UpdateDialogs { ProgressDialog, ExpenseDialog, TimeDialog }
import from .display { PlanStep, parse_plan, level_of, fmt_clock, next_quarter_minutes }
sv import from ..services.state { initialize_demo_state, update_available_time }
sv import from ..services.tasks { update_task_progress }
sv import from ..services.finance { add_expense }
sv import from ..services.snapshot { StudentSnapshot, get_student_snapshot }
sv import from ..services.planning { plan_student }
sv import from ..agents.types { PlanningResponse }


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


def:pub LiforaDashboard -> JsxElement {
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

    """After any saved change: refresh state, then replan if a plan is on screen."""
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

    def set_dialog_open(name: str, open: bool) {
        if open {
            dialog = name;
        } elif not saving {
            dialog = "";
        }
    }

    profile_name = snapshot.profile.name if snapshot else "Student";
    life_stage = snapshot.profile.life_stage if snapshot else "university";
    steps: list[PlanStep] = parse_plan(plan.coordinator.daily_plan) if plan else [];
    focus_hours = 0.0;
    for step in steps {
        if step.kind != "break" {
            focus_hours = focus_hours + step.hours;
        }
    }
    has_plan = plan is not None;
    # On small screens the decision comes straight after the hero.
    cards_order = "order-3 lg:order-2" if has_plan else "order-2";
    action_order = "order-2 lg:order-3";

    return <div className="min-h-svh bg-muted/40 text-foreground">
        <AppHeader name={profile_name} lifeStage={life_stage} />

        <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-4 py-6 sm:px-6 sm:py-8">
            <div className="order-1 flex flex-col gap-4">
                <HeroPanel
                    name={profile_name}
                    thinking={planning}
                    hasResult={has_plan}
                    stale={stale}
                    lastRun={lastRun}
                    disabled={booting or not snapshot}
                    onRun={run_plan}
                />
                {planError and <ErrorBanner
                    message={planError}
                    hasPrevious={has_plan}
                    onRetry={run_plan}
                    onDismiss={lambda { planError = ""; }}
                />}
            </div>

            {if booting {
                <section aria-busy="true" className={"grid gap-4 md:grid-cols-2 lg:grid-cols-3 " + cards_order}>
                    {for i in [1, 2, 3] {
                        <div key={str(i)} className="flex flex-col gap-4 rounded-xl border bg-card p-5 shadow-sm">
                            <Skeleton className="h-10 w-40" />
                            <Skeleton className="h-9 w-28" />
                            <Skeleton className="h-24 w-full" />
                        </div>
                    }}
                </section>
            } elif bootError or not snapshot {
                <section role="alert" className={"flex flex-col items-center gap-3 rounded-xl border bg-card px-6 py-10 text-center " + cards_order}>
                    <p className="font-semibold">{bootError or "No student data yet."}</p>
                    <p className="text-sm text-muted-foreground">Check that the Lifora server is running, then try again.</p>
                    <Button variant="outline" onClick={lambda (e: MouseEvent) { load_state(); }}>Retry</Button>
                </section>
            } else {
                <section aria-label="Your situation" className={"grid gap-4 md:grid-cols-2 lg:grid-cols-3 " + cards_order}>
                    <AcademicCard
                        tasks={snapshot.academic_tasks}
                        agent={plan.academic if plan else None}
                        previousRisk={previous["academicRisk"] or ""}
                        changedTaskId={changedTaskId}
                        previousProgress={previousProgress}
                        onUpdate={lambda { set_dialog_open("progress", True); }}
                    />
                    <FinanceCard
                        finance={snapshot.finance}
                        agent={plan.finance if plan else None}
                        previousUrgency={previous["finance"] or ""}
                        previousRemaining={previousRemaining}
                        onAddExpense={lambda { set_dialog_open("expense", True); }}
                    />
                    <div className="md:col-span-2 lg:col-span-1 [&>article]:h-full">
                        <BalanceCard
                            hours={snapshot.available_time.available_hours_today}
                            previousHours={previousHours}
                            agent={plan.balance if plan else None}
                            steps={steps}
                            previousUrgency={previous["balance"] or ""}
                            onEdit={lambda { set_dialog_open("time", True); }}
                        />
                    </div>
                </section>
            }}

            {if plan {
                <div className={"flex flex-col gap-6 transition-opacity " + action_order + (" pointer-events-none opacity-60" if planning else "")}>
                    <NextAction
                        coordinator={plan.coordinator}
                        academic={plan.academic}
                        focusHours={focus_hours}
                        previousAction={previous["action"] or ""}
                    />
                </div>
                <div className={"order-4 grid items-start gap-6 transition-opacity lg:grid-cols-12 " + (" pointer-events-none opacity-60" if planning else "")}>
                    <div className="lg:col-span-5">
                        <DailyPlan steps={steps} startMinutes={planStart} />
                    </div>
                    <div className="lg:col-span-7">
                        <DecisionTrace
                            academic={plan.academic}
                            finance={plan.finance}
                            balance={plan.balance}
                            coordinator={plan.coordinator}
                            previous={previous}
                        />
                    </div>
                </div>
            } elif planning {
                <div className="order-3"><ThinkingResult /></div>
            } elif not booting and snapshot {
                <div className="order-3">
                    <EmptyResult onRun={run_plan} disabled={booting} />
                </div>
            }}
        </main>

        <footer className="border-t py-6 text-center text-sm text-muted-foreground">
            A calmer way to make progress through university.
        </footer>

        {snapshot and <ProgressDialog
            open={dialog == "progress"}
            tasks={snapshot.academic_tasks}
            saving={saving}
            onOpenChange={lambda (o: bool) { set_dialog_open("progress", o); }}
            onSave={save_progress}
        />}
        {snapshot and <ExpenseDialog
            open={dialog == "expense"}
            remaining={snapshot.finance.remaining_budget}
            saving={saving}
            onOpenChange={lambda (o: bool) { set_dialog_open("expense", o); }}
            onSave={save_expense}
        />}
        {snapshot and <TimeDialog
            open={dialog == "time"}
            hours={snapshot.available_time.available_hours_today}
            saving={saving}
            onOpenChange={lambda (o: bool) { set_dialog_open("time", o); }}
            onSave={save_time}
        />}
        <Toaster position="bottom-right" richColors={True} />
    </div>;
}
