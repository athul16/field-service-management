package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.ProfileResponse;
import com.fieldservice.backend.entity.Profile;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MeController {

    @GetMapping("/api/me")
    public ProfileResponse me(@AuthenticationPrincipal Profile currentUser) {
        return ProfileResponse.from(currentUser);
    }
}
