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
        site.setName(rs.getString("name"));
        site.setCompanyName(rs.getString("company_name"));
        site.setAddress(rs.getString("address"));
        site.setLatitude((Double) rs.getObject("latitude"));
        site.setLongitude((Double) rs.getObject("longitude"));
        site.setCreatedAt(rs.getTimestamp("created_at").toInstant());
        return site;
    };

    private static final RowMapper<SiteResponse> RESPONSE_ROW_MAPPER = (rs, rowNum) -> new SiteResponse(
            rs.getObject("id", UUID.class),
            rs.getString("name"),
            rs.getString("company_name"),
            rs.getString("address"),
            (Double) rs.getObject("latitude"),
            (Double) rs.getObject("longitude"));

    private final NamedParameterJdbcTemplate jdbc;

    public SiteRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<Site> findById(UUID id) {
        return jdbc.query("select * from sites where id = :id", new MapSqlParameterSource("id", id), ROW_MAPPER)
                .stream()
                .findFirst();
    }

    public List<SiteResponse> findAll() {
        return jdbc.query("select * from sites order by company_name, name", RESPONSE_ROW_MAPPER);
    }

    public Site insert(Site site) {
        if (site.getId() == null) {
            site.setId(UUID.randomUUID());
        }
        jdbc.update(
                """
                insert into sites (id, name, company_name, address, latitude, longitude)
                values (:id, :name, :companyName, :address, :latitude, :longitude)
                """,
                new MapSqlParameterSource()
                        .addValue("id", site.getId())
                        .addValue("name", site.getName())
                        .addValue("companyName", site.getCompanyName())
                        .addValue("address", site.getAddress())
                        .addValue("latitude", site.getLatitude())
                        .addValue("longitude", site.getLongitude()));
        return findById(site.getId()).orElseThrow();
    }
}
