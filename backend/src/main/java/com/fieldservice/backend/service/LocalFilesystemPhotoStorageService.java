package com.fieldservice.backend.service;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.Set;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

/**
 * Single-disk, single-instance storage — fine for the current one-deployment
 * stage but not production-final (no backup/durability, doesn't survive a
 * move to ephemeral/container infra). Swap for an S3PhotoStorageService
 * implementing the same interface before scaling past one instance.
 */
@Service
public class LocalFilesystemPhotoStorageService implements PhotoStorageService {

    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of("image/jpeg", "image/png");

    private final Path baseDir;

    public LocalFilesystemPhotoStorageService(@Value("${app.photo-storage.base-dir}") String baseDirProperty) {
        this.baseDir = Path.of(baseDirProperty).toAbsolutePath().normalize();
    }

    @Override
    public String store(UUID workerId, UUID shiftId, MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new IllegalArgumentException("Photo must be a JPEG or PNG image");
        }

        String extension = contentType.equals("image/png") ? "png" : "jpg";
        String fileName = shiftId + "_" + Instant.now().toEpochMilli() + "." + extension;

        try {
            Path workerDir = baseDir.resolve(workerId.toString());
            Files.createDirectories(workerDir);
            Path target = workerDir.resolve(fileName);
            file.transferTo(target);
        } catch (IOException e) {
            throw new UncheckedIOException("Could not store photo", e);
        }

        return "/photos/" + workerId + "/" + fileName;
    }
}
