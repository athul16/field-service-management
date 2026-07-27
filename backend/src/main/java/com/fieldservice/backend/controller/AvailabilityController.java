package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.AvailabilitySlotResponse;
import com.fieldservice.backend.dto.CreateAvailabilityRequest;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.service.AvailabilityService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/availability")
public class AvailabilityController {

    private final AvailabilityService availabilityService;

    public AvailabilityController(AvailabilityService availabilityService) {
        this.availabilityService = availabilityService;
    }

    @GetMapping
    public List<AvailabilitySlotResponse> list(@AuthenticationPrincipal Profile currentUser) {
        return availabilityService.list(currentUser.getId());
    }

    @PostMapping
    public List<AvailabilitySlotResponse> addSlots(
            @Valid @RequestBody CreateAvailabilityRequest request, @AuthenticationPrincipal Profile currentUser) {
        return availabilityService.addSlots(currentUser, request.slots());
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable UUID id, @AuthenticationPrincipal Profile currentUser) {
        availabilityService.delete(currentUser, id);
    }
}
