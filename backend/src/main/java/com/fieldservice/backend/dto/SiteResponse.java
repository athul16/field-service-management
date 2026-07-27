package com.fieldservice.backend.dto;

import java.util.UUID;

/**
 * No .from(Entity) factory — SiteService.createSite already has the
 * Project it needs in scope and builds this directly; every other read
 * (list-for-project, list-for-worker) comes from a repository RowMapper
 * that joins to projects and constructs this record itself.
 */
public record SiteResponse(
        UUID id, String name, String address, Double latitude, Double longitude, UUID projectId, String projectName) {
}
