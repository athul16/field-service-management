package com.fieldservice.backend.dto;

/** {@code pin} is the effective PIN that was set — owner-supplied or server-generated. */
public record SetPinResponse(String pin) {
}
