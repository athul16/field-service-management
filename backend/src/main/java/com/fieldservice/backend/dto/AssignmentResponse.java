package com.fieldservice.backend.dto;

import java.time.Instant;
import java.util.UUID;

/**
 * No .from(Entity) factory — AssignmentService.createAssignment already
 * has the Project/Site/Profile it needs in scope and builds this
 * directly; the list-for-worker read comes from a repository RowMapper
 * that joins to all three and constructs this record itself.
 */
public record AssignmentResponse(
        UUID id,
        UUID projectId,
        String projectName,
        UUID siteId,
        String siteName,
        String siteAddress,
        UUID workerId,
        String workerName,
        Instant assignedAt) {
}
