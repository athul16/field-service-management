package com.fieldservice.backend.service;

import com.fieldservice.backend.dto.CreateWorkerRequest;
import com.fieldservice.backend.dto.ProfileResponse;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.entity.Role;
import com.fieldservice.backend.exception.NotFoundException;
import com.fieldservice.backend.repository.ProfileRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OwnerWorkerService {

    private final ProfileRepository profileRepository;
    private final PasswordEncoder passwordEncoder;

    public OwnerWorkerService(ProfileRepository profileRepository, PasswordEncoder passwordEncoder) {
        this.profileRepository = profileRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public ProfileResponse createWorker(CreateWorkerRequest request) {
        if (profileRepository.existsByPhone(request.phone())) {
            throw new IllegalArgumentException("A profile with that phone number already exists");
        }
        Profile worker = new Profile();
        worker.setRole(Role.WORKER);
        worker.setFullName(request.fullName());
        worker.setPhone(request.phone());
        worker.setPinHash(passwordEncoder.encode(request.pin()));
        return ProfileResponse.from(profileRepository.insert(worker));
    }

    @Transactional
    public void setPin(UUID workerId, String pin) {
        profileRepository.findById(workerId)
                .orElseThrow(() -> new NotFoundException("No worker found with that id"));
        profileRepository.updatePinHash(workerId, passwordEncoder.encode(pin));
    }

    public List<ProfileResponse> listWorkers() {
        return profileRepository.findAllWorkers().stream()
                .map(ProfileResponse::from)
                .toList();
    }
}
