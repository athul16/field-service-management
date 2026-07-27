package com.fieldservice.backend.service;

import com.fieldservice.backend.dto.AssignmentResponse;
import com.fieldservice.backend.dto.CreateAssignmentRequest;
import com.fieldservice.backend.dto.SiteResponse;
import com.fieldservice.backend.entity.Assignment;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.entity.Project;
import com.fieldservice.backend.entity.Site;
import com.fieldservice.backend.exception.NotFoundException;
import com.fieldservice.backend.repository.AssignmentRepository;
import com.fieldservice.backend.repository.ProfileRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AssignmentService {

    private final AssignmentRepository assignmentRepository;
    private final ProfileRepository profileRepository;
    private final ProjectService projectService;
    private final SiteService siteService;

    public AssignmentService(
            AssignmentRepository assignmentRepository,
            ProfileRepository profileRepository,
            ProjectService projectService,
            SiteService siteService) {
        this.assignmentRepository = assignmentRepository;
        this.profileRepository = profileRepository;
        this.projectService = projectService;
        this.siteService = siteService;
    }

    @Transactional
    public AssignmentResponse createAssignment(CreateAssignmentRequest request, Profile assignedBy) {
        Project project = projectService.getProjectOrThrow(request.projectId());
        Site site = siteService.getSiteOrThrow(request.siteId());
        if (!site.getProjectId().equals(project.getId())) {
            throw new IllegalArgumentException("That site does not belong to that project");
        }
        Profile worker = profileRepository.findById(request.workerId())
                .orElseThrow(() -> new NotFoundException("No worker found with that id"));

        Assignment assignment = new Assignment();
        assignment.setProjectId(project.getId());
        assignment.setSiteId(site.getId());
        assignment.setWorkerId(worker.getId());
        assignment.setAssignedById(assignedBy.getId());
        Assignment saved = assignmentRepository.insert(assignment);
        return new AssignmentResponse(
                saved.getId(),
                project.getId(),
                project.getName(),
                site.getId(),
                site.getName(),
                worker.getId(),
                worker.getFullName(),
                saved.getAssignedAt());
    }

    /** Used by the worker-facing clock-in flow to verify a worker is actually assigned to a site before letting them clock in. */
    public boolean isWorkerAssignedToSite(UUID workerId, UUID siteId) {
        return assignmentRepository.existsByWorkerIdAndSiteId(workerId, siteId);
    }

    @Transactional(readOnly = true)
    public List<AssignmentResponse> listAssignmentsForWorker(UUID workerId) {
        return assignmentRepository.findResponsesByWorkerId(workerId);
    }

    /** Sites a worker can clock in at — the employee app's site picker. */
    @Transactional(readOnly = true)
    public List<SiteResponse> listSitesForWorker(UUID workerId) {
        return assignmentRepository.findDistinctSitesForWorker(workerId);
    }
}
