package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.CreateSiteRequest;
import com.fieldservice.backend.dto.SiteResponse;
import com.fieldservice.backend.service.SiteService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@PreAuthorize("hasRole('OWNER')")
public class OwnerSiteController {

    private final SiteService siteService;

    public OwnerSiteController(SiteService siteService) {
        this.siteService = siteService;
    }

    @PostMapping("/api/owner/projects/{projectId}/sites")
    public SiteResponse createSite(@PathVariable UUID projectId, @Valid @RequestBody CreateSiteRequest request) {
        return siteService.createSite(projectId, request);
    }

    @GetMapping("/api/owner/sites")
    public List<SiteResponse> listSites(@RequestParam UUID projectId) {
        return siteService.listSites(projectId);
    }
}
