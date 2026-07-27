package com.fieldservice.backend.repository;

import com.fieldservice.backend.entity.AvailabilitySlot;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class AvailabilitySlotRepository {

    private static final RowMapper<AvailabilitySlot> ROW_MAPPER = (rs, rowNum) -> {
        AvailabilitySlot slot = new AvailabilitySlot();
        slot.setId(rs.getObject("id", UUID.class));
        slot.setWorkerId(rs.getObject("worker_id", UUID.class));
        slot.setStartAt(rs.getTimestamp("start_at").toInstant());
        slot.setEndAt(rs.getTimestamp("end_at").toInstant());
        slot.setCreatedAt(rs.getTimestamp("created_at").toInstant());
        return slot;
    };

    private final NamedParameterJdbcTemplate jdbc;

    public AvailabilitySlotRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<AvailabilitySlot> findById(UUID id) {
        return jdbc.query(
                        "select * from availability_slots where id = :id", new MapSqlParameterSource("id", id), ROW_MAPPER)
                .stream()
                .findFirst();
    }

    public List<AvailabilitySlot> findByWorkerIdOrderByStartAt(UUID workerId) {
        return jdbc.query(
                "select * from availability_slots where worker_id = :workerId order by start_at",
                new MapSqlParameterSource("workerId", workerId),
                ROW_MAPPER);
    }

    public AvailabilitySlot insert(AvailabilitySlot slot) {
        if (slot.getId() == null) {
            slot.setId(UUID.randomUUID());
        }
        jdbc.update(
                """
                insert into availability_slots (id, worker_id, start_at, end_at)
                values (:id, :workerId, :startAt, :endAt)
                """,
                new MapSqlParameterSource()
                        .addValue("id", slot.getId())
                        .addValue("workerId", slot.getWorkerId())
                        .addValue("startAt", java.sql.Timestamp.from(slot.getStartAt()))
                        .addValue("endAt", java.sql.Timestamp.from(slot.getEndAt())));
        return findById(slot.getId()).orElseThrow();
    }

    public void deleteById(UUID id) {
        jdbc.update("delete from availability_slots where id = :id", new MapSqlParameterSource("id", id));
    }
}
