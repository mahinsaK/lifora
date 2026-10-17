import from "@jac/runtime" { Link }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ChartIncreaseIcon,
    Wallet01Icon,
    HourglassIcon,
    ArrowRight01Icon,
    InformationCircleIcon
    ,PlusSignIcon
}
import from ..components.ui.skeleton { Skeleton }
import from ..components.ui.spinner { Spinner }
import from ..components.UpdateForms { AddTaskForm, EditTaskForm, IncomeForm, ProgressForm, ExpenseForm, TimeForm, TransactionHistory, ProfileGoalsForm, FormHeading }
import from ..components.PageParts { PageHeader }
import from ..components.LiforaProvider { useLifora }


"""/update - change real student state; Lifora replans automatically."""
def:pub UpdatePage -> JsxPage {
    app = useLifora();
    snapshot = app["snapshot"];
    plan = app["plan"];
    planning: bool = app["planning"];
    saving: bool = app["saving"];

    return <div className="flex flex-col gap-6">
        <PageHeader
            eyebrow="Your day"
            title="Update your situation"
            description="Changes are saved to your profile. If you already have a plan, Lifora replans straight away."
        />

        {if planning {
            <div aria-live="polite" className="flex items-center gap-2 rounded-xl border border-primary/30 bg-primary/5 px-4 py-3 text-sm font-medium text-primary">
                <Spinner className="size-4" />
                Replanning with your new situation…
            </div>
        } elif plan and app["previous"]["action"] {
            <Link to="/plan" className="group flex items-center justify-between gap-3 rounded-xl border border-primary/30 bg-primary/5 px-4 py-3 text-sm focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50">
                <span><span className="font-semibold text-primary">Plan updated. </span>{plan.coordinator.next_action}</span>
                <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="size-4 shrink-0 text-primary transition-transform group-hover:translate-x-0.5" />
            </Link>
        } elif not plan {
            <p className="flex items-center gap-2 rounded-xl border bg-card px-4 py-3 text-sm text-muted-foreground">
                <HugeiconsIcon icon={InformationCircleIcon} strokeWidth={2} className="size-4 shrink-0" />
                No plan yet. Save your changes, then ask Lifora what to do next from the Overview.
            </p>
        }}

        {if not snapshot {
            <div className="grid gap-4 lg:grid-cols-3">
                {for i in [1, 2, 3] {
                    <div key={str(i)} className="flex flex-col gap-4 rounded-xl border bg-card p-5 shadow-sm">
                        <Skeleton className="h-10 w-48" />
                        <Skeleton className="h-40 w-full" />
                    </div>
                }}
            </div>
            skip;
        }}

        <div className="grid items-start gap-4 lg:grid-cols-2">
            <section className="flex flex-col gap-5 rounded-xl border bg-card p-5 shadow-sm">
                <FormHeading icon={PlusSignIcon} title="Add task" description="Create coursework with a deadline and effort estimate." />
                <AddTaskForm saving={saving} onSave={app["saveTask"]} />
            </section>
            <section className="flex flex-col gap-5 rounded-xl border bg-card p-5 shadow-sm">
                <FormHeading icon={ChartIncreaseIcon} title="Edit task details" description="Adjust task details or mark work complete." />
                <EditTaskForm tasks={snapshot.academic_tasks} saving={saving} onSave={app["saveTaskDetails"]} onComplete={app["completeTask"]} />
            </section>
            <section className="flex flex-col gap-5 rounded-xl border bg-card p-5 shadow-sm">
                <FormHeading icon={Wallet01Icon} title="Add income" description="Add funds to your weekly budget." />
                <IncomeForm saving={saving} onSave={app["saveIncome"]} />
            </section>
            <section className="flex flex-col gap-5 rounded-xl border bg-card p-5 shadow-sm">
                <FormHeading icon={ChartIncreaseIcon} title="Assignment progress" description="How far along are you?" />
                <ProgressForm tasks={snapshot.academic_tasks} saving={saving} onSave={app["saveProgress"]} />
            </section>
            <section className="flex flex-col gap-5 rounded-xl border bg-card p-5 shadow-sm">
                <FormHeading icon={Wallet01Icon} title="Add expense" description="Logged to today's spending." />
                <ExpenseForm remaining={snapshot.finance.remaining_budget} saving={saving} onSave={app["saveExpense"]} />
            </section>
            <section className="flex flex-col gap-5 rounded-xl border bg-card p-5 shadow-sm">
                <FormHeading icon={HourglassIcon} title="Available time" description="Hours you can focus tonight." />
                <TimeForm hours={snapshot.available_time.available_hours_today} saving={saving} onSave={app["saveTime"]} />
            </section>
            <TransactionHistory transactions={app["transactions"]} />
            <ProfileGoalsForm
                name={snapshot.profile.name}
                lifeStage={snapshot.profile.life_stage}
                goals={app["goals"]}
                saving={saving}
                onSaveProfile={app["saveProfile"]}
                onAddGoal={app["saveGoal"]}
                onRemoveGoal={app["deleteGoal"]}
            />
        </div>
    </div>;
}
