package com.fieldservice.backend.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * No .from(Entity) factory — every read that needs this shape (active
 * shift, owner search, timesheet week, post-clock-out re-read) goes
 * through a repository RowMapper that joins to profiles/sites directly;
 * clockIn builds one manually from the Profile/Site it already has in
 * scope from validating the request. clockOutPhotoUrls is always in
 * upload order (position 0 first) and empty (never null) before clock-out.
 */
public record ShiftResponse(
        UUID id,
        UUID workerId,
        String workerName,
        UUID siteId,
        String siteName,
        Instant clockInAt,
        Instant clockOutAt,
        List<String> clockOutPhotoUrls,
        String status,
        Instant confirmedAt) {
}
