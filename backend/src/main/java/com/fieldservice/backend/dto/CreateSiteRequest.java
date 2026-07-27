package com.fieldservice.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateSiteRequest(@NotBlank String name, @NotBlank String address, Double latitude, Double longitude) {
}
