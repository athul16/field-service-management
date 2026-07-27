package com.fieldservice.backend.service;

import com.fieldservice.backend.dto.ShiftResponse;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.entity.Shift;
import com.fieldservice.backend.entity.ShiftStatus;
import com.fieldservice.backend.entity.Site;
import com.fieldservice.backend.exception.AccessDeniedAppException;
import com.fieldservice.backend.exception.NotFoundException;
import com.fieldservice.backend.repository.ShiftRepository;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
public class ShiftService {

    private final ShiftRepository shiftRepository;
    private final AssignmentService assignmentService;
    private final SiteService siteService;
    private final PhotoStorageService photoStorageService;

    public ShiftService(
            ShiftRepository shiftRepository,
            AssignmentService assignmentService,
            SiteService siteService,
            PhotoStorageService photoStorageService) {
        this.shiftRepository = shiftRepository;
        this.assignmentService = assignmentService;
        this.siteService = siteService;
        this.photoStorageService = photoStorageService;
    }

    /** Owner-facing history view — filters are all optional. */
    @Transactional(readOnly = true)
    public List<ShiftResponse> searchForOwner(UUID workerId, UUID siteId, Instant from, Instant to) {
        return shiftRepository.searchForOwner(workerId, siteId, from, to);
    }

    @Transactional(readOnly = true)
    public Optional<ShiftResponse> getActiveShift(UUID workerId) {
        return shiftRepository.findActiveResponseForWorker(workerId);
    }

    /**
     * Verifies the worker is actually assigned to the site before letting
     * them clock in — the original Supabase RLS policy never checked this,
     * only that worker_id matched; this closes that gap rather than just
     * matching it.
     */
    @Transactional
    public ShiftResponse clockIn(Profile worker, UUID siteId) {
        if (!assignmentService.isWorkerAssignedToSite(worker.getId(), siteId)) {
            throw new AccessDeniedAppException("You are not assigned to that site");
        }
        if (shiftRepository.findByWorkerIdAndStatus(worker.getId(), ShiftStatus.IN_PROGRESS).isPresent()) {
            throw new IllegalArgumentException("You are already clocked in");
        }
        Site site = siteService.getSiteOrThrow(siteId);

        Shift shift = new Shift();
        shift.setWorkerId(worker.getId());
        shift.setSiteId(site.getId());
        shift.setStatus(ShiftStatus.IN_PROGRESS);
        Shift saved = shiftRepository.insert(shift);
        return new ShiftResponse(
                saved.getId(),
                worker.getId(),
                worker.getFullName(),
                site.getId(),
                site.getName(),
                saved.getClockInAt(),
                saved.getClockOutAt(),
                saved.getClockOutPhotoUrl(),
                saved.getStatus().name());
    }

    /** One atomic request: upload the photo, then mark the shift completed — no orphaned photo if either step fails on its own. */
    @Transactional
    public ShiftResponse clockOut(Profile worker, UUID shiftId, MultipartFile photo) {
        Shift shift = shiftRepository.findById(shiftId)
                .orElseThrow(() -> new NotFoundException("No shift found with that id"));
        if (!shift.getWorkerId().equals(worker.getId())) {
            throw new AccessDeniedAppException("That shift does not belong to you");
        }
        if (shift.getStatus() != ShiftStatus.IN_PROGRESS) {
            throw new IllegalArgumentException("That shift is already completed");
        }

        String photoUrl = photoStorageService.store(worker.getId(), shiftId, photo);

        shiftRepository.updateClockOut(shiftId, Instant.now(), photoUrl);
        return shiftRepository.findResponseById(shiftId);
    }
}
