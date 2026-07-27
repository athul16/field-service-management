package com.fieldservice.backend.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record ClockInRequest(@NotNull UUID siteId) {
}
