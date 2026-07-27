package com.fieldservice.backend.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record CreateAssignmentRequest(@NotNull UUID projectId, @NotNull UUID workerId) {
}
