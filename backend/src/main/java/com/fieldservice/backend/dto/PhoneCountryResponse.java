package com.fieldservice.backend.dto;

public record PhoneCountryResponse(String iso2, String name, String dialCode, int nationalLength) {
}
