import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { BookOpen01Icon, Wallet01Icon, Clock01Icon, SparklesIcon, ArrowRight01Icon }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }

def:pub LiforaDashboard -> JsxElement {
    return <main className="min-h-svh bg-muted/40 px-4 py-6 sm:px-8 sm:py-10">
        <div className="mx-auto flex w-full max-w-6xl flex-col gap-8 animate-in fade-in slide-in-from-bottom-2 duration-500">
            <header className="flex flex-wrap items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                    <div className="flex size-11 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm">
                        <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-5" />
                    </div>
                    <div>
                        <div className="text-xl font-semibold tracking-tight">Lifora</div>
                        <div className="text-sm text-muted-foreground">University Mode</div>
                    </div>
                </div>
                <div className="rounded-full border bg-card px-3 py-1.5 text-xs font-medium text-muted-foreground">Your personal operating system</div>
            </header>

            <section className="rounded-2xl border bg-card px-6 py-8 shadow-sm sm:px-10 sm:py-10">
                <div className="max-w-3xl">
                    <p className="mb-3 text-sm font-medium text-primary">A clearer way through student life</p>
                    <h1 className="text-balance text-3xl font-semibold leading-tight tracking-tight sm:text-4xl">One life. Many priorities. One intelligent next step.</h1>
                    <p className="mt-4 max-w-2xl text-base leading-relaxed text-muted-foreground">Bring your studies, finances, and time into view. Lifora helps you find your footing when everything is competing for attention.</p>
                    <Button className="mt-7 h-11 gap-2 px-5 shadow-sm">
                        What Should I Do Next?
                        <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="size-4" />
                    </Button>
                </div>
            </section>

            <section aria-label="Your student life" className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <Card className="shadow-sm transition-shadow hover:shadow-md">
                    <CardHeader className="flex flex-row items-start gap-4">
                        <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={BookOpen01Icon} strokeWidth={2} className="size-5" /></div>
                        <div className="flex flex-col gap-1"><CardTitle>Academic</CardTitle><CardDescription>Courses, assignments, and upcoming deadlines.</CardDescription></div>
                    </CardHeader>
                    <CardContent><div className="rounded-lg border border-dashed bg-muted/30 px-4 py-5 text-sm text-muted-foreground">Your academic picture will take shape here.</div></CardContent>
                </Card>
                <Card className="shadow-sm transition-shadow hover:shadow-md">
                    <CardHeader className="flex flex-row items-start gap-4">
                        <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={Wallet01Icon} strokeWidth={2} className="size-5" /></div>
                        <div className="flex flex-col gap-1"><CardTitle>Finance</CardTitle><CardDescription>Money matters that are part of the bigger picture.</CardDescription></div>
                    </CardHeader>
                    <CardContent><div className="rounded-lg border border-dashed bg-muted/30 px-4 py-5 text-sm text-muted-foreground">Your student finances will appear here.</div></CardContent>
                </Card>
                <Card className="shadow-sm transition-shadow hover:shadow-md">
                    <CardHeader className="flex flex-row items-start gap-4">
                        <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={Clock01Icon} strokeWidth={2} className="size-5" /></div>
                        <div className="flex flex-col gap-1"><CardTitle>Available Time</CardTitle><CardDescription>A space for the hours and energy you have.</CardDescription></div>
                    </CardHeader>
                    <CardContent><div className="rounded-lg border border-dashed bg-muted/30 px-4 py-5 text-sm text-muted-foreground">Your time today will be considered here.</div></CardContent>
                </Card>
                <Card className="border-primary/25 bg-primary/[0.03] shadow-sm transition-shadow hover:shadow-md">
                    <CardHeader className="flex flex-row items-start gap-4">
                        <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-5" /></div>
                        <div className="flex flex-col gap-1"><CardTitle>Best Next Action</CardTitle><CardDescription>The one thing most worth your attention right now.</CardDescription></div>
                    </CardHeader>
                    <CardContent><div className="rounded-lg border border-dashed border-primary/25 bg-card px-4 py-5 text-sm text-muted-foreground">Your next step will live here, with the context behind it.</div></CardContent>
                </Card>
            </section>
            <footer className="border-t pt-5 text-sm text-muted-foreground">A calmer way to make progress through university.</footer>
        </div>
    </main>;
}
