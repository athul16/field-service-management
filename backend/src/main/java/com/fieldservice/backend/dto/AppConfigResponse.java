package com.fieldservice.backend.dto;

import java.util.List;

/** Public, unauthenticated config both frontends fetch before a phone number is ever entered — needed pre-login. */
public record AppConfigResponse(List<PhoneCountryResponse> phoneCountries, String defaultCountry) {
}
