package com.fieldservice.backend.repository;

import com.fieldservice.backend.dto.ShiftResponse;
import com.fieldservice.backend.entity.Shift;
import com.fieldservice.backend.entity.ShiftStatus;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class ShiftRepository {

    private static final RowMapper<Shift> ROW_MAPPER = (rs, rowNum) -> {
        Shift shift = new Shift();
        shift.setId(rs.getObject("id", UUID.class));
        shift.setWorkerId(rs.getObject("worker_id", UUID.class));
        shift.setSiteId(rs.getObject("site_id", UUID.class));
        shift.setClockInAt(rs.getTimestamp("clock_in_at").toInstant());
        Timestamp clockOutAt = rs.getTimestamp("clock_out_at");
        shift.setClockOutAt(clockOutAt == null ? null : clockOutAt.toInstant());
        shift.setClockOutPhotoUrl(rs.getString("clock_out_photo_url"));
        shift.setStatus(ShiftStatus.fromDbValue(rs.getString("status")));
        shift.setCreatedAt(rs.getTimestamp("created_at").toInstant());
        Timestamp confirmedAt = rs.getTimestamp("confirmed_at");
        shift.setConfirmedAt(confirmedAt == null ? null : confirmedAt.toInstant());
        shift.setConfirmedBy(rs.getObject("confirmed_by", UUID.class));
        return shift;
    };

    /**
     * Joins to profiles (worker) and sites for the denormalized names every
     * ShiftResponse needs. Shared by the owner search, the timesheet week
     * read, and the post-clock-out re-read — one query shape, one mapper.
     */
    private static final RowMapper<ShiftResponse> RESPONSE_ROW_MAPPER = (rs, rowNum) -> {
        Timestamp clockOutAt = rs.getTimestamp("clock_out_at");
        Timestamp confirmedAt = rs.getTimestamp("confirmed_at");
        return new ShiftResponse(
                rs.getObject("id", UUID.class),
                rs.getObject("worker_id", UUID.class),
                rs.getString("worker_name"),
                rs.getObject("site_id", UUID.class),
                rs.getString("site_name"),
                rs.getTimestamp("clock_in_at").toInstant(),
                clockOutAt == null ? null : clockOutAt.toInstant(),
                rs.getString("clock_out_photo_url"),
                ShiftStatus.fromDbValue(rs.getString("status")).name(),
                confirmedAt == null ? null : confirmedAt.toInstant());
    };

    private static final String RESPONSE_BASE_QUERY =
            """
            select sh.id, sh.worker_id, w.full_name as worker_name, sh.site_id, s.name as site_name,
                   sh.clock_in_at, sh.clock_out_at, sh.clock_out_photo_url, sh.status, sh.confirmed_at
            from shifts sh
            join profiles w on w.id = sh.worker_id
            join sites s on s.id = sh.site_id
            """;

    private final NamedParameterJdbcTemplate jdbc;

    public ShiftRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<Shift> findById(UUID id) {
        return jdbc.query("select * from shifts where id = :id", new MapSqlParameterSource("id", id), ROW_MAPPER)
                .stream()
                .findFirst();
    }

    public Optional<Shift> findByWorkerIdAndStatus(UUID workerId, ShiftStatus status) {
        return jdbc.query(
                        "select * from shifts where worker_id = :workerId and status = :status",
                        new MapSqlParameterSource()
                                .addValue("workerId", workerId)
                                .addValue("status", status.toDbValue()),
                        ROW_MAPPER)
                .stream()
                .findFirst();
    }

    public Shift insert(Shift shift) {
        if (shift.getId() == null) {
            shift.setId(UUID.randomUUID());
        }
        jdbc.update(
                """
                insert into shifts (id, worker_id, site_id, status)
                values (:id, :workerId, :siteId, :status)
                """,
                new MapSqlParameterSource()
                        .addValue("id", shift.getId())
                        .addValue("workerId", shift.getWorkerId())
                        .addValue("siteId", shift.getSiteId())
                        .addValue("status", shift.getStatus().toDbValue()));
        return findById(shift.getId()).orElseThrow();
    }

    public void updateClockOut(UUID shiftId, Instant clockOutAt, String photoUrl) {
        jdbc.update(
                """
                update shifts
                set clock_out_at = :clockOutAt, clock_out_photo_url = :photoUrl, status = :status
                where id = :id
                """,
                new MapSqlParameterSource()
                        .addValue("id", shiftId)
                        .addValue("clockOutAt", Timestamp.from(clockOutAt))
                        .addValue("photoUrl", photoUrl)
                        .addValue("status", ShiftStatus.COMPLETED.toDbValue()));
    }

    public void confirmShift(UUID shiftId, UUID confirmedByOwnerId) {
        jdbc.update(
                "update shifts set confirmed_at = now(), confirmed_by = :ownerId where id = :id",
                new MapSqlParameterSource().addValue("id", shiftId).addValue("ownerId", confirmedByOwnerId));
    }

    public ShiftResponse findResponseById(UUID id) {
        return jdbc.queryForObject(
                RESPONSE_BASE_QUERY + " where sh.id = :id", new MapSqlParameterSource("id", id), RESPONSE_ROW_MAPPER);
    }

    public Optional<ShiftResponse> findActiveResponseForWorker(UUID workerId) {
        return jdbc.query(
                        RESPONSE_BASE_QUERY + " where sh.worker_id = :workerId and sh.status = :status",
                        new MapSqlParameterSource()
                                .addValue("workerId", workerId)
                                .addValue("status", ShiftStatus.IN_PROGRESS.toDbValue()),
                        RESPONSE_ROW_MAPPER)
                .stream()
                .findFirst();
    }

    public List<ShiftResponse> findResponsesForWeek(UUID workerId, Instant weekStart, Instant weekEnd) {
        return jdbc.query(
                RESPONSE_BASE_QUERY
                        + """
                        where sh.worker_id = :workerId
                          and sh.status = :status
                          and sh.clock_in_at >= :weekStart
                          and sh.clock_in_at < :weekEnd
                        order by sh.clock_in_at
                        """,
                new MapSqlParameterSource()
                        .addValue("workerId", workerId)
                        .addValue("status", ShiftStatus.COMPLETED.toDbValue())
                        .addValue("weekStart", Timestamp.from(weekStart))
                        .addValue("weekEnd", Timestamp.from(weekEnd)),
                RESPONSE_ROW_MAPPER);
    }

    /**
     * Owner-facing history search — every filter is optional. Each WHERE
     * fragment is appended to the SQL *and* its parameter added to the map
     * together, as one atomic step, only when that filter is non-null —
     * never add a parameter for a filter that isn't also in the SQL. A
     * param bound with no corresponding typed context is exactly what
     * caused the original "could not determine data type of parameter"
     * failure with the JPQL "(:x is null or ...)" pattern this replaces.
     */
    public List<ShiftResponse> searchForOwner(UUID workerId, UUID siteId, Instant from, Instant to) {
        StringBuilder sql = new StringBuilder(RESPONSE_BASE_QUERY).append(" where 1=1");
        MapSqlParameterSource params = new MapSqlParameterSource();

        if (workerId != null) {
            sql.append(" and sh.worker_id = :workerId");
            params.addValue("workerId", workerId);
        }
        if (siteId != null) {
            sql.append(" and sh.site_id = :siteId");
            params.addValue("siteId", siteId);
        }
        if (from != null) {
            sql.append(" and sh.clock_in_at >= :from");
            params.addValue("from", Timestamp.from(from));
        }
        if (to != null) {
            sql.append(" and sh.clock_in_at <= :to");
            params.addValue("to", Timestamp.from(to));
        }
        sql.append(" order by sh.clock_in_at desc");

        return jdbc.query(sql.toString(), params, RESPONSE_ROW_MAPPER);
    }
}
