package com.fieldservice.backend.config;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * The one place that knows which countries this deployment supports for phone numbers.
 * Unlike the rest of this codebase's plain {@code @Value} scalars, this binds a structured
 * list (Spring's normal tool for that) — deliberately so adding a country as this rolls out
 * to more regions is a single new YAML entry, not a delimited string to hand-parse.
 */
@ConfigurationProperties(prefix = "app.phone")
public class PhoneProperties {

    private String defaultCountry;
    private List<Country> countries = List.of();

    public String getDefaultCountry() {
        return defaultCountry;
    }

    public void setDefaultCountry(String defaultCountry) {
        this.defaultCountry = defaultCountry;
    }

    public List<Country> getCountries() {
        return countries;
    }

    public void setCountries(List<Country> countries) {
        this.countries = countries;
    }

    public static class Country {
        private String iso2;
        private String name;
        private String dialCode;
        private int nationalLength;

        public String getIso2() {
            return iso2;
        }

        public void setIso2(String iso2) {
            this.iso2 = iso2;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getDialCode() {
            return dialCode;
        }

        public void setDialCode(String dialCode) {
            this.dialCode = dialCode;
        }

        public int getNationalLength() {
            return nationalLength;
        }

        public void setNationalLength(int nationalLength) {
            this.nationalLength = nationalLength;
        }
    }
}
