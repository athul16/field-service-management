package com.fieldservice.backend.repository;

import com.fieldservice.backend.entity.Project;
import java.sql.Date;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class ProjectRepository {

    private static final RowMapper<Project> ROW_MAPPER = (rs, rowNum) -> {
        Project project = new Project();
        project.setId(rs.getObject("id", UUID.class));
        project.setOwnerId(rs.getObject("owner_id", UUID.class));
        project.setName(rs.getString("name"));
        project.setLocation(rs.getString("location"));
        Date startDate = rs.getDate("start_date");
        project.setStartDate(startDate == null ? null : startDate.toLocalDate());
        Date endDate = rs.getDate("end_date");
        project.setEndDate(endDate == null ? null : endDate.toLocalDate());
        project.setStatus(rs.getString("status"));
        project.setCreatedAt(rs.getTimestamp("created_at").toInstant());
        return project;
    };

    private final NamedParameterJdbcTemplate jdbc;

    public ProjectRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<Project> findById(UUID id) {
        return jdbc.query("select * from projects where id = :id", new MapSqlParameterSource("id", id), ROW_MAPPER)
                .stream()
                .findFirst();
    }

    public List<Project> findByOwnerId(UUID ownerId) {
        return jdbc.query(
                "select * from projects where owner_id = :ownerId order by created_at desc",
                new MapSqlParameterSource("ownerId", ownerId),
                ROW_MAPPER);
    }

    public Project insert(Project project) {
        if (project.getId() == null) {
            project.setId(UUID.randomUUID());
        }
        jdbc.update(
                """
                insert into projects (id, owner_id, name, location, start_date, end_date, status)
                values (:id, :ownerId, :name, :location, :startDate, :endDate, :status)
                """,
                new MapSqlParameterSource()
                        .addValue("id", project.getId())
                        .addValue("ownerId", project.getOwnerId())
                        .addValue("name", project.getName())
                        .addValue("location", project.getLocation())
                        .addValue("startDate", project.getStartDate())
                        .addValue("endDate", project.getEndDate())
                        .addValue("status", project.getStatus()));
        return findById(project.getId()).orElseThrow();
    }
}
