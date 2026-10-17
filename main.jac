import services.planning;
import ".styles.global.css";
import from .components.LiforaDashboard { LiforaDashboard }

def:pub app -> JsxElement {
    return <LiforaDashboard/>;
}
