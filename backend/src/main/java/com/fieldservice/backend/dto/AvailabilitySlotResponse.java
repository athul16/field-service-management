package com.fieldservice.backend.dto;

import com.fieldservice.backend.entity.AvailabilitySlot;
import java.time.Instant;
import java.util.UUID;

public record AvailabilitySlotResponse(UUID id, Instant startAt, Instant endAt) {
    public static AvailabilitySlotResponse from(AvailabilitySlot slot) {
        return new AvailabilitySlotResponse(slot.getId(), slot.getStartAt(), slot.getEndAt());
    }
}
