package com.fieldservice.backend.dto;

import com.fieldservice.backend.entity.Project;
import java.time.LocalDate;
import java.util.UUID;

public record ProjectResponse(
        UUID id, String name, String location, LocalDate startDate, LocalDate endDate, String status, UUID ownerId) {
    public static ProjectResponse from(Project project) {
        return new ProjectResponse(
                project.getId(),
                project.getName(),
                project.getLocation(),
                project.getStartDate(),
                project.getEndDate(),
                project.getStatus(),
                project.getOwnerId());
    }
}
