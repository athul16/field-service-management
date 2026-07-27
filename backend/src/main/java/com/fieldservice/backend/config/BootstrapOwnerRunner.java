package com.fieldservice.backend.config;

import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.entity.Role;
import com.fieldservice.backend.repository.ProfileRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * Replaces supabase/seed.sql's manual "create the first owner by hand" step.
 * Runs once at startup: if BOOTSTRAP_OWNER_PHONE/PIN are set and no profile
 * with that phone exists yet, creates it. Deliberately not an exposed HTTP
 * endpoint — nothing in production should be able to mint an owner account
 * over the network.
 */
@Component
public class BootstrapOwnerRunner implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(BootstrapOwnerRunner.class);

    private final ProfileRepository profileRepository;
    private final PasswordEncoder passwordEncoder;
    private final String phone;
    private final String pin;
    private final String fullName;

    public BootstrapOwnerRunner(
            ProfileRepository profileRepository,
            PasswordEncoder passwordEncoder,
            @Value("${app.bootstrap-owner.phone}") String phone,
            @Value("${app.bootstrap-owner.pin}") String pin,
            @Value("${app.bootstrap-owner.full-name}") String fullName) {
        this.profileRepository = profileRepository;
        this.passwordEncoder = passwordEncoder;
        this.phone = phone;
        this.pin = pin;
        this.fullName = fullName;
    }

    @Override
    public void run(String... args) {
        if (!StringUtils.hasText(phone) || !StringUtils.hasText(pin)) {
            return;
        }
        if (profileRepository.existsByPhone(phone)) {
            return;
        }

        Profile owner = new Profile();
        owner.setRole(Role.OWNER);
        owner.setFullName(fullName);
        owner.setPhone(phone);
        owner.setPinHash(passwordEncoder.encode(pin));
        profileRepository.insert(owner);

        log.info("Bootstrapped owner account for phone {}", phone);
    }
}
