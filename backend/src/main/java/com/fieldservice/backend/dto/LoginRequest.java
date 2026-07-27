package com.fieldservice.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(@NotBlank String phone, @NotBlank String pin) {
}
