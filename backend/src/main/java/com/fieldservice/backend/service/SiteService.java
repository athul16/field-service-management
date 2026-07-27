package com.fieldservice.backend.service;

import com.fieldservice.backend.dto.CreateSiteRequest;
import com.fieldservice.backend.dto.SiteResponse;
import com.fieldservice.backend.entity.Site;
import com.fieldservice.backend.exception.NotFoundException;
import com.fieldservice.backend.repository.SiteRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SiteService {

    private final SiteRepository siteRepository;

    public SiteService(SiteRepository siteRepository) {
        this.siteRepository = siteRepository;
    }

    @Transactional
    public SiteResponse createSite(CreateSiteRequest request) {
        Site site = new Site();
        site.setName(request.name());
        site.setCompanyName(request.companyName());
        site.setAddress(request.address());
        site.setLatitude(request.latitude());
        site.setLongitude(request.longitude());
        Site saved = siteRepository.insert(site);
        return new SiteResponse(
                saved.getId(), saved.getName(), saved.getCompanyName(), saved.getAddress(), saved.getLatitude(), saved.getLongitude());
    }

    @Transactional(readOnly = true)
    public List<SiteResponse> listSites() {
        return siteRepository.findAll();
    }

    public Site getSiteOrThrow(UUID siteId) {
        return siteRepository.findById(siteId).orElseThrow(() -> new NotFoundException("No site found with that id"));
    }
}
