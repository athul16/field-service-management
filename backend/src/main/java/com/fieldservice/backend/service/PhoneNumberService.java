package com.fieldservice.backend.service;

import com.fieldservice.backend.config.PhoneProperties;
import org.springframework.stereotype.Service;

/**
 * The single place phone numbers get standardized. Every phone number this system ever stores
 * or looks up goes through {@link #normalize(String)} first — strips incidental spaces/dashes,
 * requires a "+" country code, and requires the digits after it to match one of the configured
 * countries' dial code + national length exactly. This is what turns "9876543210", "+91
 * 98765 43210", and "919876543210" from three different-looking, ambiguous strings into either
 * one canonical stored value or a clear rejection — never a silent guess.
 */
@Service
public class PhoneNumberService {

    private final PhoneProperties phoneProperties;

    public PhoneNumberService(PhoneProperties phoneProperties) {
        this.phoneProperties = phoneProperties;
    }

    public String normalize(String rawPhone) {
        if (rawPhone == null || rawPhone.isBlank()) {
            throw new IllegalArgumentException("Phone number is required");
        }
        String cleaned = rawPhone.replaceAll("[\\s\\-().]", "");
        if (!cleaned.startsWith("+")) {
            throw new IllegalArgumentException("Phone number must include a country code, e.g. +14155552671");
        }
        for (PhoneProperties.Country country : phoneProperties.getCountries()) {
            if (cleaned.startsWith(country.getDialCode())) {
                String nationalPart = cleaned.substring(country.getDialCode().length());
                if (!nationalPart.matches("\\d{" + country.getNationalLength() + "}")) {
                    throw new IllegalArgumentException(
                            "Phone number for " + country.getName() + " must have " + country.getNationalLength()
                                    + " digits after " + country.getDialCode());
                }
                return cleaned;
            }
        }
        throw new IllegalArgumentException("Unsupported country code in phone number");
    }
}
