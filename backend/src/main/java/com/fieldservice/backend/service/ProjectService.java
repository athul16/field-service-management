package com.fieldservice.backend.service;

import com.fieldservice.backend.dto.CreateProjectRequest;
import com.fieldservice.backend.dto.ProjectResponse;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.entity.Project;
import com.fieldservice.backend.entity.Site;
import com.fieldservice.backend.exception.NotFoundException;
import com.fieldservice.backend.repository.ProjectRepository;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProjectService {

    private static final Set<String> VALID_STATUSES = Set.of("active", "closed");

    private final ProjectRepository projectRepository;
    private final SiteService siteService;

    public ProjectService(ProjectRepository projectRepository, SiteService siteService) {
        this.projectRepository = projectRepository;
        this.siteService = siteService;
    }

    @Transactional
    public ProjectResponse createProject(UUID siteId, CreateProjectRequest request, Profile owner) {
        Site site = siteService.getSiteOrThrow(siteId);
        Project project = new Project();
        project.setOwnerId(owner.getId());
        project.setSiteId(site.getId());
        project.setName(request.name());
        project.setStartDate(request.startDate());
        project.setEndDate(request.endDate());
        return projectRepository.insert(project);
    }

    @Transactional(readOnly = true)
    public List<ProjectResponse> listProjects(UUID ownerId) {
        return projectRepository.findResponsesByOwnerId(ownerId);
    }

    @Transactional(readOnly = true)
    public List<ProjectResponse> listForSite(UUID siteId) {
        return projectRepository.findResponsesBySiteId(siteId);
    }

    @Transactional
    public ProjectResponse updateStatus(UUID projectId, String status) {
        if (!VALID_STATUSES.contains(status)) {
            throw new IllegalArgumentException("status must be one of " + VALID_STATUSES);
        }
        getProjectOrThrow(projectId);
        return projectRepository.updateStatus(projectId, status);
    }

    public Project getProjectOrThrow(UUID projectId) {
        return projectRepository.findById(projectId)
                .orElseThrow(() -> new NotFoundException("No project found with that id"));
    }
}
