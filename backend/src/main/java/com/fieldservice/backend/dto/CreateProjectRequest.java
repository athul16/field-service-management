package com.fieldservice.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record CreateProjectRequest(@NotBlank String name, @NotNull LocalDate startDate, LocalDate endDate) {
}
