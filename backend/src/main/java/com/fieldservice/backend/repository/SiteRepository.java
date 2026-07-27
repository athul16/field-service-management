package com.fieldservice.backend.repository;

import com.fieldservice.backend.dto.SiteResponse;
import com.fieldservice.backend.entity.Site;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class SiteRepository {

    private static final RowMapper<Site> ROW_MAPPER = (rs, rowNum) -> {
        Site site = new Site();
        site.setId(rs.getObject("id", UUID.class));
        site.setProjectId(rs.getObject("project_id", UUID.class));
        site.setName(rs.getString("name"));
        site.setAddress(rs.getString("address"));
        site.setLatitude((Double) rs.getObject("latitude"));
        site.setLongitude((Double) rs.getObject("longitude"));
        site.setCreatedAt(rs.getTimestamp("created_at").toInstant());
        return site;
    };

    /** Joins to projects for project_name — used by the "list sites for display" reads, not single-row CRUD. */
    private static final RowMapper<SiteResponse> RESPONSE_ROW_MAPPER = (rs, rowNum) -> new SiteResponse(
            rs.getObject("id", UUID.class),
            rs.getString("name"),
            rs.getString("address"),
            (Double) rs.getObject("latitude"),
            (Double) rs.getObject("longitude"),
            rs.getObject("project_id", UUID.class),
            rs.getString("project_name"));

    private final NamedParameterJdbcTemplate jdbc;

    public SiteRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<Site> findById(UUID id) {
        return jdbc.query("select * from sites where id = :id", new MapSqlParameterSource("id", id), ROW_MAPPER)
                .stream()
                .findFirst();
    }

    public List<SiteResponse> findResponsesByProjectId(UUID projectId) {
        return jdbc.query(
                """
                select s.*, p.name as project_name
                from sites s
                join projects p on p.id = s.project_id
                where s.project_id = :projectId
                order by s.name
                """,
                new MapSqlParameterSource("projectId", projectId),
                RESPONSE_ROW_MAPPER);
    }

    public Site insert(Site site) {
        if (site.getId() == null) {
            site.setId(UUID.randomUUID());
        }
        jdbc.update(
                """
                insert into sites (id, project_id, name, address, latitude, longitude)
                values (:id, :projectId, :name, :address, :latitude, :longitude)
                """,
                new MapSqlParameterSource()
                        .addValue("id", site.getId())
                        .addValue("projectId", site.getProjectId())
                        .addValue("name", site.getName())
                        .addValue("address", site.getAddress())
                        .addValue("latitude", site.getLatitude())
                        .addValue("longitude", site.getLongitude()));
        return findById(site.getId()).orElseThrow();
    }
}
