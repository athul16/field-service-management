package com.fieldservice.backend.security;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class JwtService {

    private final SecretKey key;
    private final long expirationDays;

    public JwtService(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.expiration-days}") long expirationDays) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationDays = expirationDays;
    }

    public String generateToken(UUID profileId) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(profileId.toString())
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiresAt(now)))
                .signWith(key)
                .compact();
    }

    public Instant expiresAt(Instant issuedAt) {
        return issuedAt.plus(expirationDays, ChronoUnit.DAYS);
    }

    /** Throws an unchecked JJWT exception (expired/malformed/bad signature) if the token isn't valid. */
    public UUID parseSubject(String token) {
        String subject = Jwts.parser().verifyWith(key).build()
                .parseSignedClaims(token)
                .getPayload()
                .getSubject();
        return UUID.fromString(subject);
    }
}
