package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.CreateSiteRequest;
import com.fieldservice.backend.dto.SiteResponse;
import com.fieldservice.backend.service.SiteService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/owner/sites")
@PreAuthorize("hasRole('OWNER')")
public class OwnerSiteController {

    private final SiteService siteService;

    public OwnerSiteController(SiteService siteService) {
        this.siteService = siteService;
    }

    @PostMapping
    public SiteResponse createSite(@Valid @RequestBody CreateSiteRequest request) {
        return siteService.createSite(request);
    }

    @GetMapping
    public List<SiteResponse> listSites() {
        return siteService.listSites();
    }
}
