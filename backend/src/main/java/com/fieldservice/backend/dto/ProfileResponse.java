package com.fieldservice.backend.dto;

import com.fieldservice.backend.entity.Profile;
import java.util.UUID;

/** Never includes pinHash — this is the only shape a Profile is ever serialized as. */
public record ProfileResponse(UUID id, String fullName, String phone, String email, String role) {
    public static ProfileResponse from(Profile profile) {
        return new ProfileResponse(
                profile.getId(),
                profile.getFullName(),
                profile.getPhone(),
                profile.getEmail(),
                profile.getRole().name());
    }
}
