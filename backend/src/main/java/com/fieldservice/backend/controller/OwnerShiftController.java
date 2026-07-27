package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.ShiftResponse;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.service.ShiftService;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/owner/shifts")
@PreAuthorize("hasRole('OWNER')")
public class OwnerShiftController {

    private final ShiftService shiftService;

    public OwnerShiftController(ShiftService shiftService) {
        this.shiftService = shiftService;
    }

    @GetMapping
    public List<ShiftResponse> search(
            @RequestParam(required = false) UUID workerId,
            @RequestParam(required = false) UUID siteId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to) {
        return shiftService.searchForOwner(workerId, siteId, from, to);
    }

    @PatchMapping("/{id}/confirm")
    public ShiftResponse confirm(@PathVariable UUID id, @AuthenticationPrincipal Profile currentUser) {
        return shiftService.confirmShift(id, currentUser);
    }
}
