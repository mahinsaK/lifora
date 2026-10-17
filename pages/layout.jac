import from "@jac/runtime" { Outlet }
import from ..components.ui.sonner_toast { Toaster }
import from ..components.AppHeader { AppHeader }
import from ..components.UpdateForms { UpdateDialog }
import from ..components.LiforaProvider { useLifora }


"""Shared shell for every page: header + navigation, page outlet, quick-edit dialog."""
def:pub Shell -> JsxLayout {
    app = useLifora();
    snapshot = app["snapshot"];
    set_dialog = app["setDialog"];
    name = snapshot.profile.name if snapshot else "Student";
    stage = snapshot.profile.life_stage if snapshot else "university";

    return <div className="flex min-h-svh flex-col bg-muted/40 text-foreground">
        <a href="#main" className="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:z-50 focus:rounded-md focus:bg-card focus:px-3 focus:py-2">Skip to content</a>
        <AppHeader name={name} lifeStage={stage} planStale={app["stale"]} />
        <main id="main" className="mx-auto flex w-full max-w-6xl flex-1 flex-col gap-6 px-4 py-6 sm:px-6 sm:py-8">
            <Outlet />
        </main>
        <footer className="border-t py-6 text-center text-sm text-muted-foreground">
            A calmer way to make progress through university.
        </footer>
        {if snapshot {
        <UpdateDialog
            kind={app["dialog"]}
            tasks={snapshot.academic_tasks}
            remaining={snapshot.finance.remaining_budget}
            hours={snapshot.available_time.available_hours_today}
            saving={app["saving"]}
            onClose={lambda { set_dialog.call(None, ""); }}
            onSaveTask={app["saveTask"]}
            onSaveTaskDetails={app["saveTaskDetails"]}
            onCompleteTask={app["completeTask"]}
            onSaveIncome={app["saveIncome"]}
            onSaveProgress={app["saveProgress"]}
            onSaveExpense={app["saveExpense"]}
            onSaveTime={app["saveTime"]}
        />
        }}
        <Toaster position="bottom-right" richColors={True} />
    </div>;
}
