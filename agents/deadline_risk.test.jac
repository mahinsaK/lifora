import from agents.types { RiskLevel }

glob FIXED_NOW = "2026-10-17T18:00:00+05:30";

test "completed tasks have low risk even after their deadline" {
    risk = assess_deadline_risk(
        FIXED_NOW, "2026-10-16T18:00:00+05:30", 100.0, 0.0, 0.0, 5
    );

    assert risk == RiskLevel.LOW;
}

test "ample available time produces low risk" {
    risk = assess_deadline_risk(
        FIXED_NOW, "2026-10-19T18:00:00+05:30", 50.0, 2.0, 6.0, 3
    );

    assert risk == RiskLevel.LOW;
}

test "a tight but achievable deadline produces high risk" {
    risk = assess_deadline_risk(
        FIXED_NOW, "2026-10-18T02:00:00+05:30", 40.0, 3.0, 3.5, 4
    );

    assert risk == RiskLevel.HIGH;
}

test "moderate capacity pressure produces medium risk" {
    risk = assess_deadline_risk(
        FIXED_NOW, "2026-10-18T18:00:00+05:30", 50.0, 3.0, 5.0, 3
    );

    assert risk == RiskLevel.MEDIUM;
}

test "high importance escalates moderate capacity pressure" {
    risk = assess_deadline_risk(
        FIXED_NOW, "2026-10-18T18:00:00+05:30", 50.0, 3.0, 5.0, 4
    );

    assert risk == RiskLevel.HIGH;
}

test "near-complete progress reduces achievable deadline pressure" {
    risk = assess_deadline_risk(
        FIXED_NOW, "2026-10-18T23:59:00+05:30", 90.0, 3.0, 5.0, 5
    );

    assert risk == RiskLevel.MEDIUM;
}

test "work exceeding available time is critical" {
    risk = assess_deadline_risk(
        FIXED_NOW, "2026-10-18T18:00:00+05:30", 40.0, 4.0, 3.0, 5
    );

    assert risk == RiskLevel.CRITICAL;
}

test "an elapsed deadline with unfinished work is critical" {
    risk = assess_deadline_risk(
        FIXED_NOW, "2026-10-17T17:59:00+05:30", 90.0, 1.0, 4.0, 5
    );

    assert risk == RiskLevel.CRITICAL;
}

test "invalid progress is rejected" {
    with testraises(ValueError) {
        assess_deadline_risk(FIXED_NOW, "2026-10-18T18:00:00+05:30", -1.0, 2.0, 4.0, 3);
    }
    with testraises(ValueError) {
        assess_deadline_risk(
            FIXED_NOW, "2026-10-18T18:00:00+05:30", 101.0, 2.0, 4.0, 3
        );
    }
}

test "negative hour inputs are rejected" {
    with testraises(ValueError) {
        assess_deadline_risk(
            FIXED_NOW, "2026-10-18T18:00:00+05:30", 50.0, -1.0, 4.0, 3
        );
    }
    with testraises(ValueError) {
        assess_deadline_risk(
            FIXED_NOW, "2026-10-18T18:00:00+05:30", 50.0, 2.0, -1.0, 3
        );
    }
}

test "importance outside the supported scale is rejected" {
    with testraises(ValueError) {
        assess_deadline_risk(FIXED_NOW, "2026-10-18T18:00:00+05:30", 50.0, 2.0, 4.0, 0);
    }
}
