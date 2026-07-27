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
    private final PhoneNumberService phoneNumberService;

    public AuthService(
            ProfileRepository profileRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            PhoneNumberService phoneNumberService) {
        this.profileRepository = profileRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.phoneNumberService = phoneNumberService;
    }

    public LoginResponse login(LoginRequest request) {
        // An unrecognized/malformed phone is just as much "invalid credentials" to the caller
        // as a wrong PIN — don't leak phone-format validation detail on a login attempt.
        String phone;
        try {
            phone = phoneNumberService.normalize(request.phone());
        } catch (IllegalArgumentException e) {
            throw new BadCredentialsException("Invalid phone number or PIN");
        }

        Profile profile = profileRepository.findByPhone(phone)
                .orElseThrow(() -> new BadCredentialsException("Invalid phone number or PIN"));

        if (profile.getPinHash() == null || !passwordEncoder.matches(request.pin(), profile.getPinHash())) {
            throw new BadCredentialsException("Invalid phone number or PIN");
        }

        Instant now = Instant.now();
        String token = jwtService.generateToken(profile.getId());
        return new LoginResponse(token, jwtService.expiresAt(now), ProfileResponse.from(profile));
    }
}
