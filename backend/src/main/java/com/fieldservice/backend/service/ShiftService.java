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
                List.of(),
                saved.getStatus().name(),
                saved.getConfirmedAt());
    }

    private static final int MAX_CLOCK_OUT_PHOTOS = 3;

    /**
     * One atomic request: insert each photo row, then mark the shift completed. Photo storage
     * is itself a DB insert now (see DatabasePhotoStorageService), so the whole thing lives in
     * one transaction — a failure partway through leaves no orphaned photos or half-updated
     * shifts, unlike the old local-disk version where a file write couldn't roll back with the SQL.
     */
    @Transactional
    public ShiftResponse clockOut(Profile worker, UUID shiftId, List<MultipartFile> photos) {
        if (photos.isEmpty() || photos.size() > MAX_CLOCK_OUT_PHOTOS) {
            throw new IllegalArgumentException("Attach between 1 and " + MAX_CLOCK_OUT_PHOTOS + " photos");
        }
        Shift shift = shiftRepository.findById(shiftId)
                .orElseThrow(() -> new NotFoundException("No shift found with that id"));
        if (!shift.getWorkerId().equals(worker.getId())) {
            throw new AccessDeniedAppException("That shift does not belong to you");
        }
        if (shift.getStatus() != ShiftStatus.IN_PROGRESS) {
            throw new IllegalArgumentException("That shift is already completed");
        }

        for (int position = 0; position < photos.size(); position++) {
            photoStorageService.store(shiftId, position, photos.get(position));
        }

        shiftRepository.updateClockOut(shiftId, Instant.now());
        return shiftRepository.findResponseById(shiftId);
    }

    /** Only a completed shift (clocked out, photo attached) can be confirmed — idempotent if called again. */
    @Transactional
    public ShiftResponse confirmShift(UUID shiftId, Profile owner) {
        Shift shift = shiftRepository.findById(shiftId)
                .orElseThrow(() -> new NotFoundException("No shift found with that id"));
        if (shift.getStatus() != ShiftStatus.COMPLETED) {
            throw new IllegalArgumentException("Only a completed shift can be confirmed");
        }
        shiftRepository.confirmShift(shiftId, owner.getId());
        return shiftRepository.findResponseById(shiftId);
    }
}
