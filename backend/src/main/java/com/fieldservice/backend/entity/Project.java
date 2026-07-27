package com.fieldservice.backend.entity;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public class Project {

    private UUID id;
    private UUID ownerId;
    private UUID siteId;
    private String name;
    private LocalDate startDate;
    private LocalDate endDate;
    private String status = "active";
    private Instant createdAt;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getOwnerId() {
        return ownerId;
    }

    public void setOwnerId(UUID ownerId) {
        this.ownerId = ownerId;
    }

    // A project's site is fixed at creation and never re-pointed — nothing in the DB enforces
    // this, so don't add an endpoint/setter path that lets a project's site change after insert
    // (assignments derive their site_id from this at creation time and would silently drift).
    public UUID getSiteId() {
        return siteId;
    }

    public void setSiteId(UUID siteId) {
        this.siteId = siteId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}
