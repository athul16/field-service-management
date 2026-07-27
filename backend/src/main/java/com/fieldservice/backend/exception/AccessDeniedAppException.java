package com.fieldservice.backend.exception;

/**
 * Thrown when an authenticated user tries to touch a record that isn't
 * theirs (e.g. clocking out someone else's shift) — this is exactly the
 * class of check Postgres RLS used to make true by construction; now it's
 * enforced explicitly in the service layer instead. See agents.md.
 */
public class AccessDeniedAppException extends RuntimeException {
    public AccessDeniedAppException(String message) {
        super(message);
    }
}
