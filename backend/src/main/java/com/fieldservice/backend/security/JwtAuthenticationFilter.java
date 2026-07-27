package com.fieldservice.backend.security;

import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.repository.ProfileRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.UUID;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Validates the JWT and, if valid, loads the Profile fresh from the DB
 * (rather than trusting claims embedded in the token) to build the
 * SecurityContext — a role change or (future) deactivation takes effect
 * on the very next request instead of only after the token's full
 * lifetime, at the cost of one indexed PK lookup per request.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final ProfileRepository profileRepository;

    public JwtAuthenticationFilter(JwtService jwtService, ProfileRepository profileRepository) {
        this.jwtService = jwtService;
        this.profileRepository = profileRepository;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {

        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring("Bearer ".length());
            try {
                UUID profileId = jwtService.parseSubject(token);
                profileRepository.findById(profileId).ifPresent(this::authenticate);
            } catch (RuntimeException ignoredInvalidToken) {
                // Leave the SecurityContext unauthenticated; protected
                // endpoints will 401 via the entry point below.
            }
        }
        filterChain.doFilter(request, response);
    }

    private void authenticate(Profile profile) {
        var authorities = List.of(new SimpleGrantedAuthority("ROLE_" + profile.getRole().name()));
        var authentication = new UsernamePasswordAuthenticationToken(profile, null, authorities);
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }
}
