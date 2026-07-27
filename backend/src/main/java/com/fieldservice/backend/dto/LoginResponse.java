package com.fieldservice.backend.dto;

import java.time.Instant;

public record LoginResponse(String token, Instant expiresAt, ProfileResponse profile) {
}
