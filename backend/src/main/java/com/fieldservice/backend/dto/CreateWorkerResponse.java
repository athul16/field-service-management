package com.fieldservice.backend.dto;

/**
 * {@code pin} is the effective PIN that was set — owner-supplied or
 * server-generated — returned exactly once so the owner can share it with
 * the worker. Never persisted or logged in plaintext beyond this response.
 */
public record CreateWorkerResponse(ProfileResponse profile, String pin) {
}
