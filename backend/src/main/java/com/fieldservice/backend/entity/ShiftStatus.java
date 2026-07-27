package com.fieldservice.backend.entity;

public enum ShiftStatus {
    IN_PROGRESS,
    COMPLETED;

    /** The lowercase form stored in the DB (see shifts_completed_requires_clock_out and friends). */
    public String toDbValue() {
        return name().toLowerCase();
    }

    public static ShiftStatus fromDbValue(String dbValue) {
        return ShiftStatus.valueOf(dbValue.toUpperCase());
    }
}
