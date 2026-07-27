package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.CreateProjectRequest;
import com.fieldservice.backend.dto.ProjectResponse;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.service.ProjectService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/owner/projects")
@PreAuthorize("hasRole('OWNER')")
public class OwnerProjectController {

    private final ProjectService projectService;

    public OwnerProjectController(ProjectService projectService) {
        this.projectService = projectService;
    }

    @PostMapping
    public ProjectResponse createProject(
            @Valid @RequestBody CreateProjectRequest request, @AuthenticationPrincipal Profile currentUser) {
        return projectService.createProject(request, currentUser);
    }

    @GetMapping
    public List<ProjectResponse> listProjects(@AuthenticationPrincipal Profile currentUser) {
        return projectService.listProjects(currentUser.getId());
    }
}
