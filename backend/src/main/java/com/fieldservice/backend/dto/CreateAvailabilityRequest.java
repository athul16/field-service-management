package com.fieldservice.backend.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record CreateAvailabilityRequest(@NotEmpty @Valid List<AvailabilitySlotInput> slots) {
}
