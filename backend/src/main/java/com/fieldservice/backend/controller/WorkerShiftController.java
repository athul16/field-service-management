package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.ClockInRequest;
import com.fieldservice.backend.dto.ShiftResponse;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.service.ShiftService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
public class WorkerShiftController {

    private final ShiftService shiftService;

    public WorkerShiftController(ShiftService shiftService) {
        this.shiftService = shiftService;
    }

    /** No active shift is a normal, common state — not an error — so this is 200/null-ish 204, never 404. */
    @GetMapping("/api/shifts/active")
    public ResponseEntity<ShiftResponse> activeShift(@AuthenticationPrincipal Profile currentUser) {
        return shiftService.getActiveShift(currentUser.getId())
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @PostMapping("/api/shifts/clock-in")
    public ShiftResponse clockIn(@Valid @RequestBody ClockInRequest request, @AuthenticationPrincipal Profile currentUser) {
        return shiftService.clockIn(currentUser, request.siteId());
    }

    /** 1-3 photos, all under the same "photos" part name — ShiftService.clockOut enforces the count. */
    @PostMapping(value = "/api/shifts/{shiftId}/clock-out", consumes = "multipart/form-data")
    public ShiftResponse clockOut(
            @PathVariable UUID shiftId,
            @RequestParam("photos") List<MultipartFile> photos,
            @AuthenticationPrincipal Profile currentUser) {
        return shiftService.clockOut(currentUser, shiftId, photos);
    }
}
