import ".styles.global.css";
import from .components.LiforaDashboard { LiforaDashboard }
import from .services.snapshot { get_student_snapshot }

def:pub app -> JsxElement {
    return <LiforaDashboard />;
}
