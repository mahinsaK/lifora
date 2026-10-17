import from "@jac/runtime" { Link }


def:pub NotFoundPage -> JsxPage {
    return <div className="flex flex-col items-center gap-3 py-20 text-center">
        <p className="text-sm font-semibold text-primary">404</p>
        <h1 className="text-2xl font-semibold tracking-tight">This page doesn't exist</h1>
        <p className="text-sm text-muted-foreground">Head back to your overview to see what to do next.</p>
        <Link to="/" className="mt-2 inline-flex h-10 items-center rounded-lg bg-primary px-4 text-sm font-medium text-primary-foreground hover:bg-primary/90">Back to Overview</Link>
    </div>;
}
