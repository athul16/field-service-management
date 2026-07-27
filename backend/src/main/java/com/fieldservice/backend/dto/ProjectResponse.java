package com.fieldservice.backend.dto;

import java.time.LocalDate;
import java.util.UUID;

/**
 * No .from(Entity) factory — siteName only exists via a join to sites, not a projects column, so
 * every read comes from a repository RowMapper that joins and constructs this record directly.
 */
public record ProjectResponse(
        UUID id,
        String name,
        LocalDate startDate,
        LocalDate endDate,
        String status,
        UUID ownerId,
        UUID siteId,
        String siteName) {
}
