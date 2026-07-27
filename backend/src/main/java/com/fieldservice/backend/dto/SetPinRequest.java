package com.fieldservice.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record SetPinRequest(
        @NotBlank @Pattern(regexp = "^[0-9]{4,6}$", message = "PIN must be 4 to 6 digits") String pin) {
}
