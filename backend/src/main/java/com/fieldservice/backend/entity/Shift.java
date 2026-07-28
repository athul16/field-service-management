package com.fieldservice.backend.entity;

import java.time.Instant;
import java.util.UUID;

public class Shift {

    private UUID id;
    private UUID workerId;
    private UUID siteId;
    private Instant clockInAt;
    private Instant clockOutAt;

    /**
     * The DB additionally enforces this via shifts_one_open_per_worker_idx
     * (a unique partial index on worker_id where status='in_progress') and
     * shifts_completed_requires_clock_out — the service layer should not
     * rely on those alone, but they're a real backstop if it ever slips up.
     */
    private ShiftStatus status = ShiftStatus.IN_PROGRESS;

    private Instant createdAt;
    private Instant confirmedAt;
    private UUID confirmedBy;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getWorkerId() {
        return workerId;
    }

    public void setWorkerId(UUID workerId) {
        this.workerId = workerId;
    }

    public UUID getSiteId() {
        return siteId;
    }

    public void setSiteId(UUID siteId) {
        this.siteId = siteId;
    }

    public Instant getClockInAt() {
        return clockInAt;
    }

    public void setClockInAt(Instant clockInAt) {
        this.clockInAt = clockInAt;
    }

    public Instant getClockOutAt() {
        return clockOutAt;
    }

    public void setClockOutAt(Instant clockOutAt) {
        this.clockOutAt = clockOutAt;
    }

    public ShiftStatus getStatus() {
        return status;
    }

    public void setStatus(ShiftStatus status) {
        this.status = status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getConfirmedAt() {
        return confirmedAt;
    }

    public void setConfirmedAt(Instant confirmedAt) {
        this.confirmedAt = confirmedAt;
    }

    public UUID getConfirmedBy() {
        return confirmedBy;
    }

    public void setConfirmedBy(UUID confirmedBy) {
        this.confirmedBy = confirmedBy;
    }
}
