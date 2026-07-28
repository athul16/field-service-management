package com.fieldservice.backend.controller;

import com.fieldservice.backend.exception.NotFoundException;
import java.util.UUID;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

/**
 * Serves clock-out photo bytes straight out of the database — replaces the old static
 * resource mapping onto local disk. Public (see SecurityConfig's /photos/** permit-all) so
 * both frontends can load a photo directly in an &lt;img&gt; tag with no auth header, same as
 * before the storage change.
 */
@RestController
public class PhotoController {

    private final NamedParameterJdbcTemplate jdbc;

    public PhotoController(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping("/photos/{id}")
    public ResponseEntity<byte[]> getPhoto(@PathVariable UUID id) {
        var row = jdbc.query(
                        "select content_type, data from shift_photos where id = :id",
                        new MapSqlParameterSource("id", id),
                        (rs, rowNum) -> new Object[] {rs.getString("content_type"), rs.getBytes("data")})
                .stream()
                .findFirst()
                .orElseThrow(() -> new NotFoundException("No photo found with that id"));

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType((String) row[0]))
                .body((byte[]) row[1]);
    }
}
