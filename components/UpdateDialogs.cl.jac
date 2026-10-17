import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ChartIncreaseIcon,
    Wallet01Icon,
    HourglassIcon,
    Tick02Icon,
    InformationCircleIcon
}
import from .ui.button { Button }
import from .ui.dialog { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter }
import from .ui.slider { Slider }
import from .ui.field { Field, FieldLabel, FieldDescription }
import from .ui.input { Input }
import from .ui.input_group { InputGroup, InputGroupAddon, InputGroupText, InputGroupInput }
import from .ui.spinner { Spinner }
import from .display { fmt_money, fmt_hours }
sv import from ..services.state { AcademicTaskView }


"""Small toggle chip used for quick picks inside the dialogs."""
def Chip(label: str, active: bool, onPick: Callable[[], None]) -> JsxElement {
    def handle(e: MouseEvent) {
        onPick();
    }
    return <button
        type="button"
        aria-pressed={active}
        onClick={handle}
        className={"h-8 rounded-lg border px-3 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 " + ("border-primary bg-primary text-primary-foreground" if active else "bg-card hover:bg-muted")}
    >
        {label}
    </button>;
}


def DialogIcon(icon: any) -> JsxElement {
    return <span className="flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary">
        <HugeiconsIcon icon={icon} strokeWidth={2} className="size-5" />
    </span>;
}


def SaveButton(label: str, saving: bool, disabled: bool, onSave: Callable[[], None]) -> JsxElement {
    def handle(e: MouseEvent) {
        onSave();
    }
    return <Button onClick={handle} disabled={saving or disabled} className="gap-1.5">
        {saving and <Spinner className="size-3.5" />}
        {not saving and <HugeiconsIcon icon={Tick02Icon} strokeWidth={2} className="size-3.5" />}
        {"Saving…" if saving else label}
    </Button>;
}


def:pub ProgressDialog(
    open: bool,
    tasks: list[AcademicTaskView],
    saving: bool,
    onOpenChange: Callable[[bool], None],
    onSave: Callable[[str, float], None]
) -> JsxElement {
    has taskId: str = "",
        value: float = 0.0;

    can with [open] entry {
        if open and len(tasks) > 0 {
            taskId = tasks[0].id;
            value = tasks[0].progress;
        }
    }

    selected = [t for t in tasks if t.id == taskId];
    current = selected[0] if len(selected) > 0 else None;
    was = current.progress if current else 0.0;
    pct = int(round(value));

    def pick_task(t: AcademicTaskView) {
        taskId = t.id;
        value = t.progress;
    }

    def save {
        onSave(taskId, value);
    }

    return <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="gap-5 sm:max-w-md">
            <DialogHeader className="flex-row items-center gap-3">
                <DialogIcon icon={ChartIncreaseIcon} />
                <div className="flex flex-col gap-1">
                    <DialogTitle>Update assignment progress</DialogTitle>
                    <DialogDescription>Lifora uses this the next time it plans.</DialogDescription>
                </div>
            </DialogHeader>

            <Field>
                <FieldLabel>Task</FieldLabel>
                <div className="flex flex-wrap gap-2">
                    {for t in tasks {
                        <Chip key={t.id} label={t.title} active={t.id == taskId} onPick={lambda { pick_task(t); }} />
                    }}
                </div>
            </Field>

            <div className="flex items-center justify-between rounded-xl border bg-muted/40 px-4 py-3">
                <div className="flex items-baseline gap-2">
                    <span className="text-4xl font-semibold tabular-nums tracking-tight">{str(pct) + "%"}</span>
                    {current and pct != int(round(was)) and <span className="text-sm text-muted-foreground line-through">{"was " + str(int(round(was))) + "%"}</span>}
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

            <DialogFooter>
                <Button variant="ghost" onClick={lambda (e: MouseEvent) { onOpenChange(False); }}>Cancel</Button>
                <SaveButton label="Save progress" saving={saving} disabled={not current} onSave={save} />
            </DialogFooter>
        </DialogContent>
    </Dialog>;
}


def:pub ExpenseDialog(
    open: bool,
    remaining: float,
    saving: bool,
    onOpenChange: Callable[[bool], None],
    onSave: Callable[[float, str], None]
) -> JsxElement {
    has amountText: str = "",
        category: str = "Food",
        note: str = "";

    can with [open] entry {
        if open {
            amountText = "";
            category = "Food";
            note = "";
        }
    }

    amount = float(amountText) if amountText else 0.0;
    amount = 0.0 if amount != amount else amount;
    valid = amount > 0;
    after = remaining - amount;

    def save {
        description = category + (" - " + note.strip() if note.strip() else "");
        onSave(amount, description);
    }

    return <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="gap-5 sm:max-w-md">
            <DialogHeader className="flex-row items-center gap-3">
                <DialogIcon icon={Wallet01Icon} />
                <div className="flex flex-col gap-1">
                    <DialogTitle>Add expense</DialogTitle>
                    <DialogDescription>Logged to today's spending.</DialogDescription>
                </div>
            </DialogHeader>

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
                        autoFocus={True}
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

            <div className="flex items-center gap-2 rounded-lg border bg-muted/40 px-3 py-2.5 text-sm">
                <HugeiconsIcon icon={InformationCircleIcon} strokeWidth={2} className="size-4 shrink-0 text-muted-foreground" />
                <span className="text-muted-foreground">Remaining this week:</span>
                <span className="font-medium tabular-nums">{fmt_money(remaining)}</span>
                {valid and <span className="text-muted-foreground">→</span>}
                {valid and <span className={"font-semibold tabular-nums " + ("text-risk-high" if after < 0 else "text-primary")}>{fmt_money(after)}</span>}
            </div>

            <DialogFooter>
                <Button variant="ghost" onClick={lambda (e: MouseEvent) { onOpenChange(False); }}>Cancel</Button>
                <SaveButton label="Add expense" saving={saving} disabled={not valid} onSave={save} />
            </DialogFooter>
        </DialogContent>
    </Dialog>;
}


def:pub TimeDialog(
    open: bool,
    hours: float,
    saving: bool,
    onOpenChange: Callable[[bool], None],
    onSave: Callable[[float], None]
) -> JsxElement {
    has value: float = 0.0;

    can with [open] entry {
        if open {
            value = hours;
        }
    }

    def step(delta: float) {
        nxt = value + delta;
        value = 0.0 if nxt < 0 else (12.0 if nxt > 12 else nxt);
    }

    def save {
        onSave(value);
    }

    return <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="gap-5 sm:max-w-md">
            <DialogHeader className="flex-row items-center gap-3">
                <DialogIcon icon={HourglassIcon} />
                <div className="flex flex-col gap-1">
                    <DialogTitle>Update available time</DialogTitle>
                    <DialogDescription>How many hours can you realistically use tonight?</DialogDescription>
                </div>
            </DialogHeader>

            <div className="flex items-center justify-between gap-4 rounded-xl border bg-muted/40 px-4 py-3">
                <Button variant="outline" size="icon" aria-label="Less time" onClick={lambda (e: MouseEvent) { step(-0.5); }}>−</Button>
                <div className="flex flex-col items-center">
                    <span className="text-4xl font-semibold tabular-nums tracking-tight">{fmt_hours(value)}</span>
                    {value != hours and <span className="text-xs text-muted-foreground line-through">{"was " + fmt_hours(hours)}</span>}
                </div>
                <Button variant="outline" size="icon" aria-label="More time" onClick={lambda (e: MouseEvent) { step(0.5); }}>+</Button>
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

            <DialogFooter>
                <Button variant="ghost" onClick={lambda (e: MouseEvent) { onOpenChange(False); }}>Cancel</Button>
                <SaveButton label="Save time" saving={saving} disabled={False} onSave={save} />
            </DialogFooter>
        </DialogContent>
    </Dialog>;
}
