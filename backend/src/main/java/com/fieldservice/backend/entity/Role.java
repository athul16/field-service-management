package com.fieldservice.backend.entity;

public enum Role {
    OWNER,
    WORKER;

    /** The lowercase form stored in the DB (see the profiles_role_check constraint). */
    public String toDbValue() {
        return name().toLowerCase();
    }

    public static Role fromDbValue(String dbValue) {
        return Role.valueOf(dbValue.toUpperCase());
    }
}
