package com.fieldservice.backend.service;

import com.fieldservice.backend.dto.CreateProjectRequest;
import com.fieldservice.backend.dto.ProjectResponse;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.entity.Project;
import com.fieldservice.backend.exception.NotFoundException;
import com.fieldservice.backend.repository.ProjectRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProjectService {

    private final ProjectRepository projectRepository;

    public ProjectService(ProjectRepository projectRepository) {
        this.projectRepository = projectRepository;
    }

    @Transactional
    public ProjectResponse createProject(CreateProjectRequest request, Profile owner) {
        Project project = new Project();
        project.setOwnerId(owner.getId());
        project.setName(request.name());
        project.setLocation(request.location());
        project.setStartDate(request.startDate());
        project.setEndDate(request.endDate());
        return ProjectResponse.from(projectRepository.insert(project));
    }

    @Transactional(readOnly = true)
    public List<ProjectResponse> listProjects(UUID ownerId) {
        return projectRepository.findByOwnerId(ownerId).stream().map(ProjectResponse::from).toList();
    }

    public Project getProjectOrThrow(UUID projectId) {
        return projectRepository.findById(projectId)
                .orElseThrow(() -> new NotFoundException("No project found with that id"));
    }
}
