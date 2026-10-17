import from "@jac/runtime" { Link }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    AddCircleIcon,
    ArrowDown01Icon,
    ArrowRight01Icon,
    BookOpen01Icon,
    ChartIncreaseIcon,
    HourglassIcon,
    InformationCircleIcon,
    Settings02Icon,
    Wallet01Icon
}
import from ..components.ui.button { Button }
import from ..components.ui.skeleton { Skeleton }
import from ..components.ui.spinner { Spinner }
import from ..components.UpdateForms { TransactionHistory, ProfileGoalsForm }
import from ..components.PageParts { PageHeader }
import from ..components.LiforaProvider { useLifora }


def ActionCard(title: str, detail: str, icon: any, onOpen: Callable[[], None]) -> JsxElement {
    return <button type="button" onClick={lambda (e: MouseEvent) { onOpen(); }} className="group flex min-h-36 flex-col items-start gap-4 rounded-2xl border bg-card p-5 text-left shadow-sm transition-all hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-md focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50">
        <span className="flex size-11 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={icon} strokeWidth={2} className="size-5" /></span>
        <span className="mt-auto"><span className="block font-semibold">{title}</span><span className="mt-0.5 block text-sm text-muted-foreground">{detail}</span></span>
    </button>;
}


"""/update - focused actions first, secondary management on demand."""
def:pub UpdatePage -> JsxPage {
    app = useLifora();
    snapshot = app["snapshot"];
    plan = app["plan"];
    planning: bool = app["planning"];
    saving: bool = app["saving"];
    set_dialog = app["setDialog"];

    return <div className="flex flex-col gap-6">
        <PageHeader eyebrow="Keep Lifora current" title="What changed?" description="Choose one action. Lifora saves it, refreshes your situation, and updates an existing plan automatically." />

        {if planning {
            <div aria-live="polite" className="flex items-center gap-2 rounded-xl border border-primary/30 bg-primary/5 px-4 py-3 text-sm font-medium text-primary"><Spinner className="size-4" />Replanning with your new situation…</div>
        } elif plan and app["previous"]["action"] {
            <Link to="/plan" className="group flex items-center justify-between gap-3 rounded-xl border border-primary/30 bg-primary/5 px-4 py-3 text-sm"><span><span className="font-semibold text-primary">Plan updated. </span>{plan.coordinator.next_action}</span><HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="size-4 text-primary" /></Link>
        } elif not plan {
            <p className="flex items-center gap-2 rounded-xl border bg-card px-4 py-3 text-sm text-muted-foreground"><HugeiconsIcon icon={InformationCircleIcon} strokeWidth={2} className="size-4" />No decision yet. Your changes will be ready when you select Find My Next Step.</p>
        }}

        {if not snapshot {
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">{for i in [1, 2, 3, 4] { <Skeleton key={str(i)} className="h-36 rounded-2xl" /> }}</div>
        } else {
        <div className="contents">

        <section aria-labelledby="common-actions" className="flex flex-col gap-3">
            <div><p className="text-xs font-semibold uppercase tracking-wider text-primary">Most common</p><h2 id="common-actions" className="text-lg font-semibold">Quick actions</h2></div>
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                <ActionCard title="Add task" detail="Create coursework with its deadline and effort." icon={BookOpen01Icon} onOpen={lambda { set_dialog.call(None, "task"); }} />
                <ActionCard title="Add income" detail="Add allowance, salary, or other available funds." icon={AddCircleIcon} onOpen={lambda { set_dialog.call(None, "income"); }} />
                <ActionCard title="Add expense" detail="Record spending and update your weekly balance." icon={Wallet01Icon} onOpen={lambda { set_dialog.call(None, "expense"); }} />
                <ActionCard title="Update focus time" detail="Set realistic study or work hours left today." icon={HourglassIcon} onOpen={lambda { set_dialog.call(None, "time"); }} />
            </div>
        </section>

        <section className="grid gap-3 md:grid-cols-2">
            <article className="flex items-center justify-between gap-4 rounded-2xl border bg-card p-5 shadow-sm">
                <div className="flex items-center gap-3"><span className="flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={ChartIncreaseIcon} strokeWidth={2} className="size-5" /></span><div><h2 className="font-semibold">Task progress</h2><p className="text-sm text-muted-foreground">Update progress, details, or completion.</p></div></div>
                <div className="flex shrink-0 flex-col gap-2 sm:flex-row"><Button size="sm" variant="outline" onClick={lambda (e: MouseEvent) { set_dialog.call(None, "progress"); }}>Progress</Button><Button size="sm" variant="outline" onClick={lambda (e: MouseEvent) { set_dialog.call(None, "edit-task"); }}>Details</Button></div>
            </article>
            <a href="#profile-goals" className="flex items-center justify-between gap-4 rounded-2xl border bg-card p-5 shadow-sm transition-colors hover:border-primary/40">
                <div className="flex items-center gap-3"><span className="flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={Settings02Icon} strokeWidth={2} className="size-5" /></span><div><h2 className="font-semibold">More settings</h2><p className="text-sm text-muted-foreground">Profile, goals, and financial history.</p></div></div>
                <HugeiconsIcon icon={ArrowDown01Icon} strokeWidth={2} className="size-4 text-muted-foreground" />
            </a>
        </section>

        <details id="profile-goals" className="group rounded-2xl border bg-card shadow-sm">
            <summary className="flex cursor-pointer list-none items-center justify-between px-5 py-4"><span><span className="block font-semibold">Profile and goals</span><span className="block text-sm text-muted-foreground">Personal context used by Lifora</span></span><HugeiconsIcon icon={ArrowDown01Icon} strokeWidth={2} className="size-4 transition-transform group-open:rotate-180" /></summary>
            <div className="border-t p-4"><ProfileGoalsForm name={snapshot.profile.name} lifeStage={snapshot.profile.life_stage} goals={app["goals"]} saving={saving} onSaveProfile={app["saveProfile"]} onAddGoal={app["saveGoal"]} onRemoveGoal={app["deleteGoal"]} /></div>
        </details>
        <details className="group rounded-2xl border bg-card shadow-sm">
            <summary className="flex cursor-pointer list-none items-center justify-between px-5 py-4"><span><span className="block font-semibold">Transaction history</span><span className="block text-sm text-muted-foreground">Review recorded income and expenses</span></span><HugeiconsIcon icon={ArrowDown01Icon} strokeWidth={2} className="size-4 transition-transform group-open:rotate-180" /></summary>
            <div className="border-t p-4"><TransactionHistory transactions={app["transactions"]} onAddIncome={lambda { set_dialog.call(None, "income"); }} onAddExpense={lambda { set_dialog.call(None, "expense"); }} /></div>
        </details>
        </div>
        }}
    </div>;
}
