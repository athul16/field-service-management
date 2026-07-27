package com.fieldservice.backend.repository;

import com.fieldservice.backend.dto.AssignmentResponse;
import com.fieldservice.backend.dto.SiteResponse;
import com.fieldservice.backend.entity.Assignment;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class AssignmentRepository {

    private static final RowMapper<AssignmentResponse> RESPONSE_ROW_MAPPER = (rs, rowNum) -> new AssignmentResponse(
            rs.getObject("id", UUID.class),
            rs.getObject("project_id", UUID.class),
            rs.getString("project_name"),
            rs.getObject("site_id", UUID.class),
            rs.getString("site_name"),
            rs.getObject("worker_id", UUID.class),
            rs.getString("worker_name"),
            rs.getTimestamp("assigned_at").toInstant());

    private static final RowMapper<SiteResponse> SITE_RESPONSE_ROW_MAPPER = (rs, rowNum) -> new SiteResponse(
            rs.getObject("id", UUID.class),
            rs.getString("name"),
            rs.getString("company_name"),
            rs.getString("address"),
            (Double) rs.getObject("latitude"),
            (Double) rs.getObject("longitude"));

    private final NamedParameterJdbcTemplate jdbc;

    public AssignmentRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public boolean existsByWorkerIdAndSiteId(UUID workerId, UUID siteId) {
        Boolean exists = jdbc.queryForObject(
                "select exists(select 1 from assignments where worker_id = :workerId and site_id = :siteId)",
                new MapSqlParameterSource().addValue("workerId", workerId).addValue("siteId", siteId),
                Boolean.class);
        return Boolean.TRUE.equals(exists);
    }

    private static final RowMapper<Assignment> ROW_MAPPER = (rs, rowNum) -> {
        Assignment assignment = new Assignment();
        assignment.setId(rs.getObject("id", UUID.class));
        assignment.setProjectId(rs.getObject("project_id", UUID.class));
        assignment.setSiteId(rs.getObject("site_id", UUID.class));
        assignment.setWorkerId(rs.getObject("worker_id", UUID.class));
        assignment.setAssignedById(rs.getObject("assigned_by", UUID.class));
        assignment.setAssignedAt(rs.getTimestamp("assigned_at").toInstant());
        var notifiedAt = rs.getTimestamp("notified_at");
        assignment.setNotifiedAt(notifiedAt == null ? null : notifiedAt.toInstant());
        return assignment;
    };

    /**
     * Returns the plain entity, not the joined response — the caller
     * (AssignmentService.createAssignment) already has the Project/Site/
     * Profile in scope from validating the request, so it builds the
     * response DTO itself rather than paying for a second joined query.
     */
    public Assignment insert(Assignment assignment) {
        if (assignment.getId() == null) {
            assignment.setId(UUID.randomUUID());
        }
        jdbc.update(
                """
                insert into assignments (id, project_id, site_id, worker_id, assigned_by)
                values (:id, :projectId, :siteId, :workerId, :assignedById)
                """,
                new MapSqlParameterSource()
                        .addValue("id", assignment.getId())
                        .addValue("projectId", assignment.getProjectId())
                        .addValue("siteId", assignment.getSiteId())
                        .addValue("workerId", assignment.getWorkerId())
                        .addValue("assignedById", assignment.getAssignedById()));

        return jdbc.queryForObject(
                "select * from assignments where id = :id", new MapSqlParameterSource("id", assignment.getId()), ROW_MAPPER);
    }

    public List<AssignmentResponse> findResponsesByWorkerId(UUID workerId) {
        return jdbc.query(
                """
                select a.id, a.project_id, p.name as project_name, a.site_id, s.name as site_name,
                       a.worker_id, w.full_name as worker_name, a.assigned_at
                from assignments a
                join projects p on p.id = a.project_id
                join sites s on s.id = a.site_id
                join profiles w on w.id = a.worker_id
                where a.worker_id = :workerId
                order by a.assigned_at desc
                """,
                new MapSqlParameterSource("workerId", workerId),
                RESPONSE_ROW_MAPPER);
    }

    /**
     * Sites a worker can clock in at — the employee app's site picker.
     * Deduplicated in SQL (a worker assigned to the same site via more than
     * one assignment row must only see it once) via GROUP BY on the site's
     * own columns, not a Java-side .distinct() — a plain POJO has no
     * equals()/hashCode() override, so .distinct() on freshly-built objects
     * would silently fall back to reference equality and stop deduping.
     */
    public List<SiteResponse> findDistinctSitesForWorker(UUID workerId) {
        return jdbc.query(
                """
                select s.id, s.name, s.company_name, s.address, s.latitude, s.longitude
                from assignments a
                join sites s on s.id = a.site_id
                where a.worker_id = :workerId
                group by s.id, s.name, s.company_name, s.address, s.latitude, s.longitude
                order by s.name
                """,
                new MapSqlParameterSource("workerId", workerId),
                SITE_RESPONSE_ROW_MAPPER);
    }
}
