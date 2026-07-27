package com.fieldservice.backend.dto;

import java.util.UUID;

/**
 * No .from(Entity) factory — SiteService.createSite builds this directly from the entity it just
 * inserted; every other read comes from a repository RowMapper that constructs this record itself.
 */
public record SiteResponse(
        UUID id, String name, String companyName, String address, Double latitude, Double longitude) {
}
