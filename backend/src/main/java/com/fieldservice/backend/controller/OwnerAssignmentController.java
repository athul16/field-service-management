package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.AssignmentResponse;
import com.fieldservice.backend.dto.CreateAssignmentRequest;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.service.AssignmentService;
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
@RequestMapping("/api/owner/assignments")
@PreAuthorize("hasRole('OWNER')")
public class OwnerAssignmentController {

    private final AssignmentService assignmentService;

    public OwnerAssignmentController(AssignmentService assignmentService) {
        this.assignmentService = assignmentService;
    }

    @PostMapping
    public AssignmentResponse createAssignment(
            @Valid @RequestBody CreateAssignmentRequest request, @AuthenticationPrincipal Profile currentUser) {
        return assignmentService.createAssignment(request, currentUser);
    }

    /** Every assignment across every worker — backs the Reports page's project attribution (see agents.md). */
    @GetMapping
    public List<AssignmentResponse> listAll() {
        return assignmentService.listAll();
    }
}
