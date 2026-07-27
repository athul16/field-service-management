package com.fieldservice.backend.controller;

import com.fieldservice.backend.config.PhoneProperties;
import com.fieldservice.backend.dto.AppConfigResponse;
import com.fieldservice.backend.dto.PhoneCountryResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** Public — both frontends need this before a user has logged in (login screen's country selector). */
@RestController
public class AppConfigController {

    private final PhoneProperties phoneProperties;

    public AppConfigController(PhoneProperties phoneProperties) {
        this.phoneProperties = phoneProperties;
    }

    @GetMapping("/api/config")
    public AppConfigResponse getConfig() {
        return new AppConfigResponse(
                phoneProperties.getCountries().stream()
                        .map(c -> new PhoneCountryResponse(c.getIso2(), c.getName(), c.getDialCode(), c.getNationalLength()))
                        .toList(),
                phoneProperties.getDefaultCountry());
    }
}
