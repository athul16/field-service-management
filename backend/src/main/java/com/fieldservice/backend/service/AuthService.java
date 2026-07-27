package com.fieldservice.backend.service;

import com.fieldservice.backend.dto.LoginRequest;
import com.fieldservice.backend.dto.LoginResponse;
import com.fieldservice.backend.dto.ProfileResponse;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.repository.ProfileRepository;
import com.fieldservice.backend.security.JwtService;
import java.time.Instant;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final ProfileRepository profileRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(ProfileRepository profileRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.profileRepository = profileRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public LoginResponse login(LoginRequest request) {
        Profile profile = profileRepository.findByPhone(request.phone())
                .orElseThrow(() -> new BadCredentialsException("Invalid phone number or PIN"));

        if (profile.getPinHash() == null || !passwordEncoder.matches(request.pin(), profile.getPinHash())) {
            throw new BadCredentialsException("Invalid phone number or PIN");
        }

        Instant now = Instant.now();
        String token = jwtService.generateToken(profile.getId());
        return new LoginResponse(token, jwtService.expiresAt(now), ProfileResponse.from(profile));
    }
}
