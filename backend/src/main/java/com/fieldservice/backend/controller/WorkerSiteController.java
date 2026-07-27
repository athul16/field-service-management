package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.SiteResponse;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.service.AssignmentService;
import java.util.List;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class WorkerSiteController {

    private final AssignmentService assignmentService;

    public WorkerSiteController(AssignmentService assignmentService) {
        this.assignmentService = assignmentService;
    }

    @GetMapping("/api/sites/assigned")
    public List<SiteResponse> assignedSites(@AuthenticationPrincipal Profile currentUser) {
        return assignmentService.listSitesForWorker(currentUser.getId());
    }
}
