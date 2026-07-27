package com.fieldservice.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateProjectStatusRequest(@NotBlank String status) {
}
