import from agents.mock_snapshot { build_demo_snapshot }
import from test_support { assert_value_error }

test "what-if scenarios modify copies and preserve the source snapshot" {
    source = build_demo_snapshot();
    less_time = build_simulated_snapshot(source, "less_time");
    spending = build_simulated_snapshot(source, "spend");
    finished = build_simulated_snapshot(source, "finish_ml");

    assert source.available_time.available_hours_today == 5.0;
    assert less_time.available_time.available_hours_today == 3.0;
    assert source.finance.remaining_budget == 3500.0;
    assert spending.finance.remaining_budget == 1500.0;
    assert spending.finance.spent_today == 3500.0;
    assert source.academic_tasks[0].progress == 40.0;
    assert finished.academic_tasks[0].progress == 100.0;
    assert finished.academic_tasks[0].estimated_remaining_hours == 0.0;
}

test "what-if simulation rejects unknown scenarios" {
    assert_value_error(
        lambda { build_simulated_snapshot(build_demo_snapshot(), "unknown"); },
        "Unknown simulation scenario"
    );
}
