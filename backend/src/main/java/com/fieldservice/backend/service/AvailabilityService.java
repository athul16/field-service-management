package com.fieldservice.backend.service;

import com.fieldservice.backend.dto.AvailabilitySlotInput;
import com.fieldservice.backend.dto.AvailabilitySlotResponse;
import com.fieldservice.backend.entity.AvailabilitySlot;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.exception.AccessDeniedAppException;
import com.fieldservice.backend.exception.NotFoundException;
import com.fieldservice.backend.repository.AvailabilitySlotRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AvailabilityService {

    private final AvailabilitySlotRepository availabilitySlotRepository;

    public AvailabilityService(AvailabilitySlotRepository availabilitySlotRepository) {
        this.availabilitySlotRepository = availabilitySlotRepository;
    }

    @Transactional(readOnly = true)
    public List<AvailabilitySlotResponse> list(UUID workerId) {
        return availabilitySlotRepository.findByWorkerIdOrderByStartAt(workerId).stream()
                .map(AvailabilitySlotResponse::from)
                .toList();
    }

    @Transactional
    public List<AvailabilitySlotResponse> addSlots(Profile worker, List<AvailabilitySlotInput> slots) {
        return slots.stream()
                .map(input -> {
                    if (!input.endAt().isAfter(input.startAt())) {
                        throw new IllegalArgumentException("endAt must be after startAt");
                    }
                    AvailabilitySlot slot = new AvailabilitySlot();
                    slot.setWorkerId(worker.getId());
                    slot.setStartAt(input.startAt());
                    slot.setEndAt(input.endAt());
                    return AvailabilitySlotResponse.from(availabilitySlotRepository.insert(slot));
                })
                .toList();
    }

    @Transactional
    public void delete(Profile worker, UUID slotId) {
        AvailabilitySlot slot = availabilitySlotRepository.findById(slotId)
                .orElseThrow(() -> new NotFoundException("No availability slot found with that id"));
        if (!slot.getWorkerId().equals(worker.getId())) {
            throw new AccessDeniedAppException("That availability slot does not belong to you");
        }
        availabilitySlotRepository.deleteById(slot.getId());
    }
}
