package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.AssignmentResponse;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.service.AssignmentService;
import java.util.List;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** The current worker's own assignments (site + project names/address) — the employee app's site
 *  picker, replacing the old project-blind /api/sites/assigned now that a site can host many
 *  projects and a plain "list of sites" can no longer say which project each one is for. */
@RestController
public class WorkerAssignmentController {

    private final AssignmentService assignmentService;

    public WorkerAssignmentController(AssignmentService assignmentService) {
        this.assignmentService = assignmentService;
    }

    @GetMapping("/api/assignments")
    public List<AssignmentResponse> myAssignments(@AuthenticationPrincipal Profile currentUser) {
        return assignmentService.listAssignmentsForWorker(currentUser.getId());
    }
}
