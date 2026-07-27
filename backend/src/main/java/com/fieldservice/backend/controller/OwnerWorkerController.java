package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.CreateWorkerRequest;
import com.fieldservice.backend.dto.ProfileResponse;
import com.fieldservice.backend.dto.SetPinRequest;
import com.fieldservice.backend.service.OwnerWorkerService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/owner/workers")
@PreAuthorize("hasRole('OWNER')")
public class OwnerWorkerController {

    private final OwnerWorkerService ownerWorkerService;

    public OwnerWorkerController(OwnerWorkerService ownerWorkerService) {
        this.ownerWorkerService = ownerWorkerService;
    }

    @PostMapping
    public ProfileResponse createWorker(@Valid @RequestBody CreateWorkerRequest request) {
        return ownerWorkerService.createWorker(request);
    }

    @PostMapping("/{id}/pin")
    public void setPin(@PathVariable UUID id, @Valid @RequestBody SetPinRequest request) {
        ownerWorkerService.setPin(id, request.pin());
    }

    @GetMapping
    public List<ProfileResponse> listWorkers() {
        return ownerWorkerService.listWorkers();
    }
}
