package com.fieldservice.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record CreateProjectRequest(
        @NotBlank String name,
        @NotBlank String location,
        @NotNull LocalDate startDate,
        LocalDate endDate) {
}
