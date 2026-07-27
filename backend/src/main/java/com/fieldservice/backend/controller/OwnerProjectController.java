package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.CreateProjectRequest;
import com.fieldservice.backend.dto.ProjectResponse;
import com.fieldservice.backend.dto.UpdateProjectStatusRequest;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.service.ProjectService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@PreAuthorize("hasRole('OWNER')")
public class OwnerProjectController {

    private final ProjectService projectService;

    public OwnerProjectController(ProjectService projectService) {
        this.projectService = projectService;
    }

    @PostMapping("/api/owner/sites/{siteId}/projects")
    public ProjectResponse createProject(
            @PathVariable UUID siteId,
            @Valid @RequestBody CreateProjectRequest request,
            @AuthenticationPrincipal Profile currentUser) {
        return projectService.createProject(siteId, request, currentUser);
    }

    @GetMapping("/api/owner/projects")
    public List<ProjectResponse> listProjects(
            @RequestParam(required = false) UUID siteId, @AuthenticationPrincipal Profile currentUser) {
        return siteId != null ? projectService.listForSite(siteId) : projectService.listProjects(currentUser.getId());
    }

    @PatchMapping("/api/owner/projects/{id}/status")
    public ProjectResponse updateStatus(@PathVariable UUID id, @Valid @RequestBody UpdateProjectStatusRequest request) {
        return projectService.updateStatus(id, request.status());
    }
}
