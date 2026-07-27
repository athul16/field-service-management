package com.fieldservice.backend.dto;

import jakarta.validation.constraints.NotNull;
import java.time.Instant;

/** Client (Flutter) computes the absolute UTC instants itself — same discipline that already applies to shift timestamps. */
public record AvailabilitySlotInput(@NotNull Instant startAt, @NotNull Instant endAt) {
}
