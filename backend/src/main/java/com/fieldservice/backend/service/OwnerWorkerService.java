package com.fieldservice.backend.service;

import com.fieldservice.backend.dto.AssignmentResponse;
import com.fieldservice.backend.dto.AvailabilitySlotResponse;
import com.fieldservice.backend.dto.CreateWorkerRequest;
import com.fieldservice.backend.dto.CreateWorkerResponse;
import com.fieldservice.backend.dto.ProfileResponse;
import com.fieldservice.backend.dto.SetPinResponse;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.entity.Role;
import com.fieldservice.backend.exception.NotFoundException;
import com.fieldservice.backend.repository.AvailabilitySlotRepository;
import com.fieldservice.backend.repository.ProfileRepository;
import java.security.SecureRandom;
import java.util.List;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class OwnerWorkerService {

    private final ProfileRepository profileRepository;
    private final PasswordEncoder passwordEncoder;
    private final AvailabilitySlotRepository availabilitySlotRepository;
    private final AssignmentService assignmentService;
    private final SecureRandom secureRandom = new SecureRandom();

    public OwnerWorkerService(
            ProfileRepository profileRepository,
            PasswordEncoder passwordEncoder,
            AvailabilitySlotRepository availabilitySlotRepository,
            AssignmentService assignmentService) {
        this.profileRepository = profileRepository;
        this.passwordEncoder = passwordEncoder;
        this.availabilitySlotRepository = availabilitySlotRepository;
        this.assignmentService = assignmentService;
    }

    @Transactional
    public CreateWorkerResponse createWorker(CreateWorkerRequest request) {
        if (profileRepository.existsByPhone(request.phone())) {
            throw new IllegalArgumentException("A profile with that phone number already exists");
        }
        String pin = StringUtils.hasText(request.pin()) ? request.pin() : generatePin();

        Profile worker = new Profile();
        worker.setRole(Role.WORKER);
        worker.setFullName(request.fullName());
        worker.setPhone(request.phone());
        worker.setPinHash(passwordEncoder.encode(pin));
        Profile saved = profileRepository.insert(worker);
        return new CreateWorkerResponse(ProfileResponse.from(saved), pin);
    }

    @Transactional
    public SetPinResponse setPin(UUID workerId, String requestedPin) {
        profileRepository.findById(workerId)
                .orElseThrow(() -> new NotFoundException("No worker found with that id"));
        String pin = StringUtils.hasText(requestedPin) ? requestedPin : generatePin();
        profileRepository.updatePinHash(workerId, passwordEncoder.encode(pin));
        return new SetPinResponse(pin);
    }

    public List<ProfileResponse> listWorkers() {
        return profileRepository.findAllWorkers().stream()
                .map(ProfileResponse::from)
                .toList();
    }

    public ProfileResponse getWorker(UUID workerId) {
        return profileRepository.findById(workerId)
                .map(ProfileResponse::from)
                .orElseThrow(() -> new NotFoundException("No worker found with that id"));
    }

    /** Owner-facing view of a specific worker's availability — deliberately not routed through
     *  AvailabilityService, which is conventionally scoped to the authenticated worker only. */
    public List<AvailabilitySlotResponse> getAvailability(UUID workerId) {
        return availabilitySlotRepository.findByWorkerIdOrderByStartAt(workerId).stream()
                .map(AvailabilitySlotResponse::from)
                .toList();
    }

    public List<AssignmentResponse> getAssignments(UUID workerId) {
        return assignmentService.listAssignmentsForWorker(workerId);
    }

    private String generatePin() {
        return String.format("%06d", secureRandom.nextInt(1_000_000));
    }
}
