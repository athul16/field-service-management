package com.fieldservice.backend.repository;

import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.entity.Role;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class ProfileRepository {

    private static final RowMapper<Profile> ROW_MAPPER = (rs, rowNum) -> {
        Profile profile = new Profile();
        profile.setId(rs.getObject("id", UUID.class));
        profile.setRole(Role.fromDbValue(rs.getString("role")));
        profile.setFullName(rs.getString("full_name"));
        profile.setPhone(rs.getString("phone"));
        profile.setEmail(rs.getString("email"));
        profile.setPinHash(rs.getString("pin_hash"));
        profile.setCreatedAt(rs.getTimestamp("created_at").toInstant());
        return profile;
    };

    private final NamedParameterJdbcTemplate jdbc;

    public ProfileRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<Profile> findById(UUID id) {
        return jdbc.query("select * from profiles where id = :id", new MapSqlParameterSource("id", id), ROW_MAPPER)
                .stream()
                .findFirst();
    }

    public Optional<Profile> findByPhone(String phone) {
        return jdbc.query(
                        "select * from profiles where phone = :phone", new MapSqlParameterSource("phone", phone), ROW_MAPPER)
                .stream()
                .findFirst();
    }

    public boolean existsByPhone(String phone) {
        Boolean exists = jdbc.queryForObject(
                "select exists(select 1 from profiles where phone = :phone)",
                new MapSqlParameterSource("phone", phone),
                Boolean.class);
        return Boolean.TRUE.equals(exists);
    }

    public Profile insert(Profile profile) {
        if (profile.getId() == null) {
            profile.setId(UUID.randomUUID());
        }
        jdbc.update(
                """
                insert into profiles (id, role, full_name, phone, email, pin_hash)
                values (:id, :role, :fullName, :phone, :email, :pinHash)
                """,
                new MapSqlParameterSource()
                        .addValue("id", profile.getId())
                        .addValue("role", profile.getRole().toDbValue())
                        .addValue("fullName", profile.getFullName())
                        .addValue("phone", profile.getPhone())
                        .addValue("email", profile.getEmail())
                        .addValue("pinHash", profile.getPinHash()));
        return findById(profile.getId()).orElseThrow();
    }

    public void updatePinHash(UUID id, String pinHash) {
        jdbc.update(
                "update profiles set pin_hash = :pinHash where id = :id",
                new MapSqlParameterSource().addValue("id", id).addValue("pinHash", pinHash));
    }

    public List<Profile> findAllWorkers() {
        return jdbc.query("select * from profiles where role = 'worker' order by full_name", ROW_MAPPER);
    }
}
