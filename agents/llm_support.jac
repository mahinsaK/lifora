import os;


def openai_narratives_configured -> bool {
    return bool(os.environ.get("OPENAI_API_KEY", "").strip());
}
