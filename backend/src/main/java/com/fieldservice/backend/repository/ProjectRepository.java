package com.fieldservice.backend.repository;

import com.fieldservice.backend.dto.ProjectResponse;
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
        project.setSiteId(rs.getObject("site_id", UUID.class));
        project.setName(rs.getString("name"));
        Date startDate = rs.getDate("start_date");
        project.setStartDate(startDate == null ? null : startDate.toLocalDate());
        Date endDate = rs.getDate("end_date");
        project.setEndDate(endDate == null ? null : endDate.toLocalDate());
        project.setStatus(rs.getString("status"));
        project.setCreatedAt(rs.getTimestamp("created_at").toInstant());
        return project;
    };

    /** Joins to sites for site_name — used by every read (site_name isn't a projects column). */
    private static final RowMapper<ProjectResponse> RESPONSE_ROW_MAPPER = (rs, rowNum) -> {
        Date startDate = rs.getDate("start_date");
        Date endDate = rs.getDate("end_date");
        return new ProjectResponse(
                rs.getObject("id", UUID.class),
                rs.getString("name"),
                startDate == null ? null : startDate.toLocalDate(),
                endDate == null ? null : endDate.toLocalDate(),
                rs.getString("status"),
                rs.getObject("owner_id", UUID.class),
                rs.getObject("site_id", UUID.class),
                rs.getString("site_name"));
    };

    private static final String RESPONSE_SELECT =
            "select p.*, s.name as site_name from projects p join sites s on s.id = p.site_id";

    private final NamedParameterJdbcTemplate jdbc;

    public ProjectRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<Project> findById(UUID id) {
        return jdbc.query("select * from projects where id = :id", new MapSqlParameterSource("id", id), ROW_MAPPER)
                .stream()
                .findFirst();
    }

    public List<ProjectResponse> findResponsesByOwnerId(UUID ownerId) {
        return jdbc.query(
                RESPONSE_SELECT + " where p.owner_id = :ownerId order by p.created_at desc",
                new MapSqlParameterSource("ownerId", ownerId),
                RESPONSE_ROW_MAPPER);
    }

    public List<ProjectResponse> findResponsesBySiteId(UUID siteId) {
        return jdbc.query(
                RESPONSE_SELECT + " where p.site_id = :siteId order by p.created_at desc",
                new MapSqlParameterSource("siteId", siteId),
                RESPONSE_ROW_MAPPER);
    }

    public ProjectResponse insert(Project project) {
        if (project.getId() == null) {
            project.setId(UUID.randomUUID());
        }
        jdbc.update(
                """
                insert into projects (id, owner_id, site_id, name, start_date, end_date, status)
                values (:id, :ownerId, :siteId, :name, :startDate, :endDate, :status)
                """,
                new MapSqlParameterSource()
                        .addValue("id", project.getId())
                        .addValue("ownerId", project.getOwnerId())
                        .addValue("siteId", project.getSiteId())
                        .addValue("name", project.getName())
                        .addValue("startDate", project.getStartDate())
                        .addValue("endDate", project.getEndDate())
                        .addValue("status", project.getStatus()));
        return jdbc.queryForObject(
                RESPONSE_SELECT + " where p.id = :id", new MapSqlParameterSource("id", project.getId()), RESPONSE_ROW_MAPPER);
    }

    public ProjectResponse updateStatus(UUID id, String status) {
        jdbc.update(
                "update projects set status = :status where id = :id",
                new MapSqlParameterSource().addValue("id", id).addValue("status", status));
        return jdbc.queryForObject(
                RESPONSE_SELECT + " where p.id = :id", new MapSqlParameterSource("id", id), RESPONSE_ROW_MAPPER);
    }
}
