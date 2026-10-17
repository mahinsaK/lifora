import re;


def assert_value_error(action: Callable[[], object], message_pattern: str = "") {
    try {
        _ = action();
    } except ValueError as error {
        if message_pattern != "" {
            assert re.search(message_pattern, str(error)) is not None;
        }
        return;
    }
    assert False , "expected ValueError";
}
