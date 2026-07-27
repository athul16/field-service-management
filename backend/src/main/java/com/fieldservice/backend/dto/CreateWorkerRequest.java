package com.fieldservice.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/** {@code pin} is optional — if blank/omitted, the backend generates a random 6-digit PIN. */
public record CreateWorkerRequest(
        @NotBlank String fullName,
        @NotBlank String phone,
        @Pattern(regexp = "^[0-9]{4,6}$", message = "PIN must be 4 to 6 digits") String pin) {
}
