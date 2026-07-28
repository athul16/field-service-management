package com.fieldservice.backend.service;

import java.util.UUID;
import org.springframework.web.multipart.MultipartFile;

public interface PhotoStorageService {
    /**
     * Stores one clock-out photo at the given position (0-2, upload order) for a shift and
     * returns a URL the app can resolve against its API base URL (e.g. "/photos/<id>").
     */
    String store(UUID shiftId, int position, MultipartFile file);
}
