"""State update forms for academic, finance and availability changes.

Each form works inline (Update page) and inside a dialog (quick edits from any
page). Saving is delegated to the shared provider through `onSave`.
"""

import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ChartIncreaseIcon,
    Wallet01Icon,
    HourglassIcon,
    Tick02Icon,
    InformationCircleIcon,
    MinusSignIcon,
    PlusSignIcon
}
import from .ui.button { Button }
import from .ui.dialog { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription }
import from .ui.slider { Slider }
import from .ui.field { Field, FieldLabel, FieldDescription }
import from .ui.input { Input }
import from .ui.input_group { InputGroup, InputGroupAddon, InputGroupText, InputGroupInput }
import from .ui.spinner { Spinner }
import from .display { fmt_money, fmt_hours, deadline_label }
sv import from ..services.state { AcademicTaskView, GoalView, TransactionView }


"""Toggle chip used for quick picks."""
def Chip(label: str, active: bool, onPick: Callable[[], None]) -> JsxElement {
    def handle(e: MouseEvent) {
        onPick();
    }
    return <button
        type="button"
        aria-pressed={active}
        onClick={handle}
        className={"h-9 rounded-lg border px-3 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 " + ("border-primary bg-primary text-primary-foreground" if active else "bg-card hover:bg-muted")}
    >
        {label}
    </button>;
}


def FormActions(
    label: str,
    saving: bool,
    disabled: bool,
    onSave: Callable[[], None],
    onCancel: Callable[[], None] | None
) -> JsxElement {
    def handle_save(e: MouseEvent) {
        onSave();
    }
    def handle_cancel(e: MouseEvent) {
        if onCancel {
            onCancel();
        }
    }
    return <div className="flex flex-col-reverse gap-2 border-t pt-4 sm:flex-row sm:justify-end">
        {onCancel and <Button variant="ghost" onClick={handle_cancel}>Cancel</Button>}
        <Button onClick={handle_save} disabled={saving or disabled} className="gap-1.5">
            {saving and <Spinner className="size-3.5" />}
            {not saving and <HugeiconsIcon icon={Tick02Icon} strokeWidth={2} className="size-3.5" />}
            {"Saving…" if saving else label}
        </Button>
    </div>;
}


def:pub FormHeading(icon: any, title: str, description: str) -> JsxElement {
    return <div className="flex items-center gap-3">
        <span className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary">
            <HugeiconsIcon icon={icon} strokeWidth={2} className="size-5" />
        </span>
        <div className="flex flex-col gap-0.5">
            <h2 className="text-base font-semibold leading-tight">{title}</h2>
            <p className="text-sm text-muted-foreground">{description}</p>
        </div>
    </div>;
}


def:pub ProgressForm(
    tasks: list[AcademicTaskView],
    saving: bool,
    onSave: Callable[[str, float], None],
    onCancel: Callable[[], None] | None = None
) -> JsxElement {
    has taskId: str = "",
        value: float = 0.0;

    can with [tasks] entry {
        keep = [t for t in tasks if t.id == taskId];
        pick = keep[0] if len(keep) > 0 else (tasks[0] if len(tasks) > 0 else None);
        if pick {
            taskId = pick.id;
            value = pick.progress;
        }
    }

    selected = [t for t in tasks if t.id == taskId];
    current = selected[0] if len(selected) > 0 else None;
    was = int(round(current.progress)) if current else 0;
    pct = int(round(value));

    def pick_task(t: AcademicTaskView) {
        taskId = t.id;
        value = t.progress;
    }

    def save {
        onSave(taskId, value);
    }

    return <div className="flex flex-col gap-5">
        <Field>
            <FieldLabel>Task</FieldLabel>
            <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap">
                {for t in tasks {
                    <button
                        key={t.id}
                        type="button"
                        aria-pressed={t.id == taskId}
                        onClick={lambda (e: MouseEvent) { pick_task(t); }}
                        className={"flex flex-col items-start rounded-lg border px-3 py-2 text-left transition-colors focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 " + ("border-primary bg-primary/5" if t.id == taskId else "bg-card hover:bg-muted")}
                    >
                        <span className="text-sm font-medium">{t.title}</span>
                        <span className="text-xs text-muted-foreground">{str(int(round(t.progress))) + "% · " + deadline_label(t.deadline)}</span>
                    </button>
                }}
            </div>
        </Field>

        <div className="flex items-center justify-between rounded-xl border bg-muted/40 px-4 py-3">
            <div className="flex items-baseline gap-2">
                <span className="text-4xl font-semibold tabular-nums tracking-tight">{str(pct) + "%"}</span>
                {current and pct != was and <span className="text-sm text-muted-foreground line-through">{"was " + str(was) + "%"}</span>}
            </div>
            <span className="text-sm font-medium text-primary">{"Complete" if pct >= 100 else ("Almost there" if pct >= 80 else "In progress")}</span>
        </div>

        <Field>
            <FieldLabel className="sr-only">Progress</FieldLabel>
            <Slider
                value={[value]}
                min={0}
                max={100}
                step={5}
                aria-label="Progress percent"
                onValueChange={lambda (v: list[float]) { value = v[0]; }}
                className="py-2"
            />
            <div className="flex justify-between text-xs text-muted-foreground">
                <span>0%</span>
                <span>100%</span>
            </div>
        </Field>

        <Field>
            <FieldLabel>Quick set</FieldLabel>
            <div className="flex flex-wrap gap-2">
                <Chip label="25%" active={pct == 25} onPick={lambda { value = 25.0; }} />
                <Chip label="50%" active={pct == 50} onPick={lambda { value = 50.0; }} />
                <Chip label="75%" active={pct == 75} onPick={lambda { value = 75.0; }} />
                <Chip label="90%" active={pct == 90} onPick={lambda { value = 90.0; }} />
                <Chip label="Done" active={pct == 100} onPick={lambda { value = 100.0; }} />
            </div>
        </Field>

        <FormActions label="Save progress" saving={saving} disabled={not current or pct == was} onSave={save} onCancel={onCancel} />
    </div>;
}


def:pub AddTaskForm(
    saving: bool,
    onSave: Callable[[str, str, float, float, int], None],
    onCancel: Callable[[], None] | None = None
) -> JsxElement {
    has title: str = "",
        deadline: str = "",
        progressText: str = "0",
        hoursText: str = "",
        importance: int = 3;

    progressValue = float(progressText) if progressText else 0.0;
    hoursValue = float(hoursText) if hoursText else 0.0;
    progress = 0.0 if progressValue != progressValue else progressValue;
    hours = 0.0 if hoursValue != hoursValue else hoursValue;
    valid = bool(title.strip()) and bool(deadline) and progress >= 0 and progress <= 100 and hours >= 0 and bool(hoursText);

    def save {
        onSave(title.strip(), deadline, progress, hours, importance);
    }

    return <div className="flex flex-col gap-4">
        <Field>
            <FieldLabel htmlFor="task-title">Task title</FieldLabel>
            <Input id="task-title" placeholder="Database Systems Exam" value={title} onChange={lambda (e: ChangeEvent) { title = e.target.value; }} />
        </Field>
        <Field>
            <FieldLabel htmlFor="task-deadline">Deadline</FieldLabel>
            <Input id="task-deadline" type="date" value={deadline} onChange={lambda (e: ChangeEvent) { deadline = e.target.value; }} />
        </Field>
        <div className="grid gap-4 sm:grid-cols-2">
            <Field>
                <FieldLabel htmlFor="task-progress">Current progress (%)</FieldLabel>
                <Input id="task-progress" type="number" min="0" max="100" value={progressText} onChange={lambda (e: ChangeEvent) { progressText = e.target.value; }} />
            </Field>
            <Field>
                <FieldLabel htmlFor="task-hours">Hours remaining</FieldLabel>
                <Input id="task-hours" type="number" min="0" step="0.5" placeholder="3" value={hoursText} onChange={lambda (e: ChangeEvent) { hoursText = e.target.value; }} />
            </Field>
        </div>
        <Field>
            <FieldLabel>Importance</FieldLabel>
            <div className="flex flex-wrap gap-2">
                {for level in [1, 2, 3, 4, 5] {
                    <span key={str(level)}><Chip label={str(level)} active={importance == level} onPick={lambda { importance = level; }} /></span>
                }}
            </div>
            <FieldDescription>1 is low priority; 5 is essential.</FieldDescription>
        </Field>
        <FormActions label="Create task" saving={saving} disabled={not valid} onSave={save} onCancel={onCancel} />
    </div>;
}


def:pub EditTaskForm(
    tasks: list[AcademicTaskView],
    saving: bool,
    onSave: Callable[[str, str, str, float, float, int], None],
    onComplete: Callable[[str], None],
    onCancel: Callable[[], None] | None = None
) -> JsxElement {
    has taskId: str = "",
        title: str = "",
        deadline: str = "",
        progress: float = 0.0,
        hoursText: str = "",
        importance: int = 3;

    can with [tasks] entry {
        selected = [t for t in tasks if t.id == taskId];
        task = selected[0] if len(selected) > 0 else (tasks[0] if len(tasks) > 0 else None);
        if task {
            taskId = task.id;
            title = task.title;
            deadline = task.deadline;
            progress = task.progress;
            hoursText = str(task.estimated_remaining_hours);
            importance = task.importance;
        }
    }

    def pick_task(task: AcademicTaskView) {
        taskId = task.id;
        title = task.title;
        deadline = task.deadline;
        progress = task.progress;
        hoursText = str(task.estimated_remaining_hours);
        importance = task.importance;
    }
    parsedHours = float(hoursText) if hoursText else -1.0;
    hours = -1.0 if parsedHours != parsedHours else parsedHours;
    valid = bool(taskId) and bool(title.strip()) and bool(deadline) and hours >= 0;

    return <div className="flex flex-col gap-4">
        <Field>
            <FieldLabel>Task</FieldLabel>
            <div className="flex flex-wrap gap-2">
                {for task in tasks {
                    <button key={task.id} type="button" onClick={lambda (e: MouseEvent) { pick_task(task); }} className={"rounded-lg border px-3 py-2 text-sm font-medium " + ("border-primary bg-primary/5" if task.id == taskId else "hover:bg-muted")}>{task.title}</button>
                }}
            </div>
        </Field>
        <Field><FieldLabel htmlFor="edit-task-title">Title</FieldLabel><Input id="edit-task-title" value={title} onChange={lambda (e: ChangeEvent) { title = e.target.value; }} /></Field>
        <div className="grid gap-4 sm:grid-cols-2">
            <Field><FieldLabel htmlFor="edit-task-deadline">Deadline</FieldLabel><Input id="edit-task-deadline" type="date" value={deadline} onChange={lambda (e: ChangeEvent) { deadline = e.target.value; }} /></Field>
            <Field><FieldLabel htmlFor="edit-task-hours">Hours remaining</FieldLabel><Input id="edit-task-hours" type="number" min="0" step="0.5" value={hoursText} onChange={lambda (e: ChangeEvent) { hoursText = e.target.value; }} /></Field>
        </div>
        <Field>
            <FieldLabel>Importance</FieldLabel>
            <div className="flex flex-wrap gap-2">{for level in [1, 2, 3, 4, 5] { <span key={str(level)}><Chip label={str(level)} active={importance == level} onPick={lambda { importance = level; }} /></span> }}</div>
        </Field>
        <div className="flex flex-col-reverse gap-2 border-t pt-4 sm:flex-row sm:justify-end">
            {onCancel and <Button variant="ghost" onClick={lambda (e: MouseEvent) { onCancel(); }}>Cancel</Button>}
            <Button variant="outline" disabled={saving or not taskId or progress >= 100} onClick={lambda (e: MouseEvent) { onComplete(taskId); }}>Mark completed</Button>
            <Button disabled={saving or not valid} onClick={lambda (e: MouseEvent) { onSave(taskId, title.strip(), deadline, progress, hours, importance); }}>Save details</Button>
        </div>
    </div>;
}


def:pub ExpenseForm(
    remaining: float,
    saving: bool,
    onSave: Callable[[float, str], None],
    onCancel: Callable[[], None] | None = None
) -> JsxElement {
    has amountText: str = "",
        category: str = "Food",
        note: str = "";

    can with [remaining] entry {
        amountText = "";
        note = "";
    }

    parsed = float(amountText) if amountText else 0.0;
    amount = 0.0 if parsed != parsed else parsed;
    valid = amount > 0;
    after = remaining - amount;

    def save {
        description = category + (" - " + note.strip() if note.strip() else "");
        onSave(amount, description);
    }

    return <div className="flex flex-col gap-5">
        <Field>
            <FieldLabel htmlFor="expense-amount">Amount</FieldLabel>
            <InputGroup className="h-11">
                <InputGroupAddon><InputGroupText>Rs.</InputGroupText></InputGroupAddon>
                <InputGroupInput
                    id="expense-amount"
                    type="number"
                    inputMode="decimal"
                    min="0"
                    placeholder="1000"
                    value={amountText}
                    onChange={lambda (e: ChangeEvent) { amountText = e.target.value; }}
                    className="text-lg tabular-nums"
                />
            </InputGroup>
            <div className="flex flex-wrap gap-2">
                <Chip label="Rs. 500" active={amount == 500} onPick={lambda { amountText = "500"; }} />
                <Chip label="Rs. 1,000" active={amount == 1000} onPick={lambda { amountText = "1000"; }} />
                <Chip label="Rs. 2,000" active={amount == 2000} onPick={lambda { amountText = "2000"; }} />
            </div>
        </Field>

        <Field>
            <FieldLabel>Category</FieldLabel>
            <div className="flex flex-wrap gap-2">
                <Chip label="Food" active={category == "Food"} onPick={lambda { category = "Food"; }} />
                <Chip label="Transport" active={category == "Transport"} onPick={lambda { category = "Transport"; }} />
                <Chip label="Study" active={category == "Study"} onPick={lambda { category = "Study"; }} />
                <Chip label="Other" active={category == "Other"} onPick={lambda { category = "Other"; }} />
            </div>
        </Field>

        <Field>
            <FieldLabel htmlFor="expense-note">Note <span className="font-normal text-muted-foreground">(optional)</span></FieldLabel>
            <Input
                id="expense-note"
                placeholder="Dinner with friends"
                value={note}
                onChange={lambda (e: ChangeEvent) { note = e.target.value; }}
                className="h-10"
            />
        </Field>

        <div className="flex flex-wrap items-center gap-2 rounded-lg border bg-muted/40 px-3 py-2.5 text-sm">
            <HugeiconsIcon icon={InformationCircleIcon} strokeWidth={2} className="size-4 shrink-0 text-muted-foreground" />
            <span className="text-muted-foreground">Left this week:</span>
            <span className="font-medium tabular-nums">{fmt_money(remaining)}</span>
            {valid and <span className="text-muted-foreground">→</span>}
            {valid and <span className={"font-semibold tabular-nums " + ("text-risk-high" if after < 0 else "text-primary")}>{fmt_money(after)}</span>}
        </div>

        <FormActions label="Add expense" saving={saving} disabled={not valid} onSave={save} onCancel={onCancel} />
    </div>;
}


def:pub IncomeForm(
    saving: bool,
    onSave: Callable[[float, str, str], None],
    onCancel: Callable[[], None] | None = None
) -> JsxElement {
    has amountText: str = "",
        description: str = "",
        receivedOn: str = "";
    parsed = float(amountText) if amountText else 0.0;
    amount = 0.0 if parsed != parsed else parsed;
    valid = amount > 0 and bool(description.strip()) and bool(receivedOn);

    def save {
        onSave(amount, description.strip(), receivedOn);
    }

    return <div className="flex flex-col gap-4">
        <Field>
            <FieldLabel htmlFor="income-amount">Amount</FieldLabel>
            <InputGroup className="h-11">
                <InputGroupAddon><InputGroupText>Rs.</InputGroupText></InputGroupAddon>
                <InputGroupInput id="income-amount" type="number" min="0" inputMode="decimal" placeholder="5000" value={amountText} onChange={lambda (e: ChangeEvent) { amountText = e.target.value; }} />
            </InputGroup>
        </Field>
        <Field>
            <FieldLabel htmlFor="income-description">Description</FieldLabel>
            <Input id="income-description" placeholder="Allowance or part-time work" value={description} onChange={lambda (e: ChangeEvent) { description = e.target.value; }} />
        </Field>
        <Field>
            <FieldLabel htmlFor="income-date">Date received</FieldLabel>
            <Input id="income-date" type="date" value={receivedOn} onChange={lambda (e: ChangeEvent) { receivedOn = e.target.value; }} />
        </Field>
        <FormActions label="Add income" saving={saving} disabled={not valid} onSave={save} onCancel={onCancel} />
    </div>;
}


def:pub TransactionHistory(transactions: list[TransactionView]) -> JsxElement {
    return <section className="flex flex-col gap-4 rounded-xl border bg-card p-5 shadow-sm lg:col-span-2">
        <FormHeading icon={Wallet01Icon} title="Transaction history" description="Income and expenses recorded in your graph." />
        {if len(transactions) == 0 {
            <p className="rounded-lg border border-dashed px-4 py-6 text-center text-sm text-muted-foreground">No transactions recorded yet.</p>
        } else {
            <ul className="divide-y rounded-lg border">
                {for transaction in transactions {
                    <li key={transaction.kind + transaction.id} className="flex items-center justify-between gap-4 px-4 py-3">
                        <div className="min-w-0">
                            <p className="truncate text-sm font-medium">{transaction.description}</p>
                            <p className="text-xs text-muted-foreground">{transaction.occurred_on + " · " + transaction.kind.lower()}</p>
                        </div>
                        <span className={"shrink-0 font-semibold tabular-nums " + ("text-primary" if transaction.kind == "INCOME" else "text-risk-high")}>
                            {("+" if transaction.kind == "INCOME" else "−") + fmt_money(transaction.amount)}
                        </span>
                    </li>
                }}
            </ul>
        }}
    </section>;
}


def:pub ProfileGoalsForm(
    name: str,
    lifeStage: str,
    goals: list[GoalView],
    saving: bool,
    onSaveProfile: Callable[[str, str], None],
    onAddGoal: Callable[[str], None],
    onRemoveGoal: Callable[[str], None]
) -> JsxElement {
    has nameText: str = "",
        stageText: str = "",
        goalText: str = "";
    can with [name, lifeStage] entry {
        nameText = name;
        stageText = lifeStage;
    }
    return <section className="flex flex-col gap-5 rounded-xl border bg-card p-5 shadow-sm lg:col-span-2">
        <FormHeading icon={InformationCircleIcon} title="Profile and goals" description="Keep the context used in your plans up to date." />
        <div className="grid gap-4 sm:grid-cols-2">
            <Field><FieldLabel htmlFor="profile-name">Name</FieldLabel><Input id="profile-name" value={nameText} onChange={lambda (e: ChangeEvent) { nameText = e.target.value; }} /></Field>
            <Field><FieldLabel htmlFor="profile-stage">Life stage</FieldLabel><Input id="profile-stage" value={stageText} onChange={lambda (e: ChangeEvent) { stageText = e.target.value; }} /></Field>
        </div>
        <div className="flex justify-end"><Button disabled={saving or not nameText.strip() or not stageText.strip() or (nameText == name and stageText == lifeStage)} onClick={lambda (e: MouseEvent) { onSaveProfile(nameText.strip(), stageText.strip()); }}>Save profile</Button></div>
        <div className="flex flex-col gap-3 border-t pt-4">
            <Field><FieldLabel htmlFor="new-goal">New goal</FieldLabel><div className="flex gap-2"><Input id="new-goal" placeholder="Finish the semester strongly" value={goalText} onChange={lambda (e: ChangeEvent) { goalText = e.target.value; }} /><Button disabled={saving or not goalText.strip()} onClick={lambda (e: MouseEvent) { onAddGoal(goalText.strip()); goalText = ""; }}>Add goal</Button></div></Field>
            <ul className="flex flex-col gap-2">
                {for goal in goals {
                    <li key={goal.id} className="flex items-center justify-between gap-3 rounded-lg border px-3 py-2"><span className="text-sm font-medium">{goal.title}</span><Button variant="ghost" size="sm" disabled={saving} onClick={lambda (e: MouseEvent) { onRemoveGoal(goal.id); }}>Remove</Button></li>
                }}
                {if len(goals) == 0 { <li className="rounded-lg border border-dashed px-3 py-4 text-center text-sm text-muted-foreground">No goals yet.</li> }}
            </ul>
        </div>
    </section>;
}


def:pub TimeForm(
    hours: float,
    saving: bool,
    onSave: Callable[[float], None],
    onCancel: Callable[[], None] | None = None
) -> JsxElement {
    has value: float = 0.0;

    can with [hours] entry {
        value = hours;
    }

    def step(delta: float) {
        nxt = value + delta;
        value = 0.0 if nxt < 0 else (12.0 if nxt > 12 else nxt);
    }

    def save {
        onSave(value);
    }

    return <div className="flex flex-col gap-5">
        <div className="flex items-center justify-between gap-4 rounded-xl border bg-muted/40 px-4 py-3">
            <Button variant="outline" size="icon" aria-label="Less time" onClick={lambda (e: MouseEvent) { step(-0.5); }}>
                <HugeiconsIcon icon={MinusSignIcon} strokeWidth={2} className="size-4" />
            </Button>
            <div className="flex flex-col items-center">
                <span className="text-4xl font-semibold tabular-nums tracking-tight">{fmt_hours(value)}</span>
                {value != hours and <span className="text-xs text-muted-foreground line-through">{"was " + fmt_hours(hours)}</span>}
            </div>
            <Button variant="outline" size="icon" aria-label="More time" onClick={lambda (e: MouseEvent) { step(0.5); }}>
                <HugeiconsIcon icon={PlusSignIcon} strokeWidth={2} className="size-4" />
            </Button>
        </div>

        <Field>
            <FieldLabel>Quick set</FieldLabel>
            <div className="flex flex-wrap gap-2">
                <Chip label="1h" active={value == 1} onPick={lambda { value = 1.0; }} />
                <Chip label="2h" active={value == 2} onPick={lambda { value = 2.0; }} />
                <Chip label="3h" active={value == 3} onPick={lambda { value = 3.0; }} />
                <Chip label="4h" active={value == 4} onPick={lambda { value = 4.0; }} />
                <Chip label="5h" active={value == 5} onPick={lambda { value = 5.0; }} />
                <Chip label="6h" active={value == 6} onPick={lambda { value = 6.0; }} />
            </div>
            <FieldDescription>Count only time you can actually focus, not the whole evening.</FieldDescription>
        </Field>

        <FormActions label="Save time" saving={saving} disabled={value == hours} onSave={save} onCancel={onCancel} />
    </div>;
}


"""Dialog wrapper so any page can open a quick edit."""
def:pub UpdateDialog(
    kind: str,
    tasks: list[AcademicTaskView],
    remaining: float,
    hours: float,
    saving: bool,
    onClose: Callable[[], None],
    onSaveTask: Callable[[str, str, float, float, int], None],
    onSaveTaskDetails: Callable[[str, str, str, float, float, int], None],
    onCompleteTask: Callable[[str], None],
    onSaveIncome: Callable[[float, str, str], None],
    onSaveProgress: Callable[[str, float], None],
    onSaveExpense: Callable[[float, str], None],
    onSaveTime: Callable[[float], None]
) -> JsxElement {
    title = "Update assignment progress";
    description = "Lifora uses this the next time it plans.";
    icon: any = ChartIncreaseIcon;
    if kind == "task" {
        title = "Add academic task";
        description = "Add a deadline so Lifora can prioritize it.";
        icon = PlusSignIcon;
    } elif kind == "edit-task" {
        title = "Edit academic task";
        description = "Change task details or mark it complete.";
        icon = ChartIncreaseIcon;
    } elif kind == "income" {
        title = "Add income";
        description = "Add funds to this week's available budget.";
        icon = Wallet01Icon;
    } elif kind == "expense" {
        title = "Add expense";
        description = "Logged to today's spending.";
        icon = Wallet01Icon;
    } elif kind == "time" {
        title = "Update available time";
        description = "How many hours can you realistically use tonight?";
        icon = HourglassIcon;
    }

    def handle_open_change(open: bool) {
        if not open {
            onClose();
        }
    }

    return <Dialog open={kind != ""} onOpenChange={handle_open_change}>
        <DialogContent className="gap-5 p-5 sm:max-w-md">
            <DialogHeader className="flex-row items-center gap-3">
                <span className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary">
                    <HugeiconsIcon icon={icon} strokeWidth={2} className="size-5" />
                </span>
                <div className="flex flex-col gap-1">
                    <DialogTitle>{title}</DialogTitle>
                    <DialogDescription>{description}</DialogDescription>
                </div>
            </DialogHeader>
            {kind == "progress" and <ProgressForm tasks={tasks} saving={saving} onSave={onSaveProgress} onCancel={onClose} />}
            {kind == "task" and <AddTaskForm saving={saving} onSave={onSaveTask} onCancel={onClose} />}
            {kind == "edit-task" and <EditTaskForm tasks={tasks} saving={saving} onSave={onSaveTaskDetails} onComplete={onCompleteTask} onCancel={onClose} />}
            {kind == "income" and <IncomeForm saving={saving} onSave={onSaveIncome} onCancel={onClose} />}
            {kind == "expense" and <ExpenseForm remaining={remaining} saving={saving} onSave={onSaveExpense} onCancel={onClose} />}
            {kind == "time" and <TimeForm hours={hours} saving={saving} onSave={onSaveTime} onCancel={onClose} />}
        </DialogContent>
    </Dialog>;
}
