package com.fieldservice.backend.service;

import java.util.UUID;
import org.springframework.web.multipart.MultipartFile;

public interface PhotoStorageService {
    /** Returns a URL path (e.g. "/photos/<workerId>/<file>") the app can resolve against its API base URL. */
    String store(UUID workerId, UUID shiftId, MultipartFile file);
}
