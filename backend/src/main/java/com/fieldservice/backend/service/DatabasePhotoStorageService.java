package com.fieldservice.backend.service;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.Set;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

/**
 * Photos live in the database, not on disk — same reasoning as everything else in this
 * backend's authorization/storage layer: one durable store, backed up alongside the rest of
 * the data, no separate filesystem to provision or lose. Fine at this scale (compact JPEGs,
 * scheduled retention keeps the table from growing forever — see PhotoRetentionService);
 * revisit only if photo volume genuinely outgrows keeping them in Postgres.
 */
@Service
public class DatabasePhotoStorageService implements PhotoStorageService {

    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of("image/jpeg", "image/png");

    private final NamedParameterJdbcTemplate jdbc;

    public DatabasePhotoStorageService(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public String store(UUID shiftId, int position, MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new IllegalArgumentException("Photo must be a JPEG or PNG image");
        }

        UUID id = UUID.randomUUID();
        byte[] data;
        try {
            data = file.getBytes();
        } catch (IOException e) {
            throw new UncheckedIOException("Could not read uploaded photo", e);
        }

        jdbc.update(
                """
                insert into shift_photos (id, shift_id, position, content_type, data)
                values (:id, :shiftId, :position, :contentType, :data)
                """,
                new MapSqlParameterSource()
                        .addValue("id", id)
                        .addValue("shiftId", shiftId)
                        .addValue("position", position)
                        .addValue("contentType", contentType)
                        .addValue("data", data));

        return "/photos/" + id;
    }
}
