package com.fieldservice.backend.service;

import com.fieldservice.backend.dto.CreateSiteRequest;
import com.fieldservice.backend.dto.SiteResponse;
import com.fieldservice.backend.entity.Project;
import com.fieldservice.backend.entity.Site;
import com.fieldservice.backend.exception.NotFoundException;
import com.fieldservice.backend.repository.SiteRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SiteService {

    private final SiteRepository siteRepository;
    private final ProjectService projectService;

    public SiteService(SiteRepository siteRepository, ProjectService projectService) {
        this.siteRepository = siteRepository;
        this.projectService = projectService;
    }

    @Transactional
    public SiteResponse createSite(UUID projectId, CreateSiteRequest request) {
        Project project = projectService.getProjectOrThrow(projectId);
        Site site = new Site();
        site.setProjectId(project.getId());
        site.setName(request.name());
        site.setAddress(request.address());
        site.setLatitude(request.latitude());
        site.setLongitude(request.longitude());
        Site saved = siteRepository.insert(site);
        return new SiteResponse(
                saved.getId(),
                saved.getName(),
                saved.getAddress(),
                saved.getLatitude(),
                saved.getLongitude(),
                project.getId(),
                project.getName());
    }

    @Transactional(readOnly = true)
    public List<SiteResponse> listSites(UUID projectId) {
        return siteRepository.findResponsesByProjectId(projectId);
    }

    public Site getSiteOrThrow(UUID siteId) {
        return siteRepository.findById(siteId).orElseThrow(() -> new NotFoundException("No site found with that id"));
    }
}
