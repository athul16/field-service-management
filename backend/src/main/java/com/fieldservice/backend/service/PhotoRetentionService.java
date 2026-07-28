package com.fieldservice.backend.service;

import com.fieldservice.backend.repository.ShiftRepository;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Clock-out photos are proof-of-work records, not permanent archives — keeping them forever
 * just grows the database for no ongoing benefit. One simple rule, no confirmed/unconfirmed
 * branching: a photo is deleted once its shift's clock-out is older than app.photo-retention.days
 * (default 30). Change the number in application.yml/env, not the code, if the policy changes.
 */
@Service
public class PhotoRetentionService {

    private static final Logger log = LoggerFactory.getLogger(PhotoRetentionService.class);

    private final ShiftRepository shiftRepository;
    private final int retentionDays;

    public PhotoRetentionService(
            ShiftRepository shiftRepository, @Value("${app.photo-retention.days:30}") int retentionDays) {
        this.shiftRepository = shiftRepository;
        this.retentionDays = retentionDays;
    }

    @Transactional
    @Scheduled(cron = "0 0 3 * * *") // once a day at 3am server time
    public void purgeOldPhotos() {
        Instant cutoff = Instant.now().minus(retentionDays, ChronoUnit.DAYS);
        int deleted = shiftRepository.deletePhotosForShiftsClockedOutBefore(cutoff);
        if (deleted > 0) {
            log.info("Photo retention: deleted {} photo(s) from shifts clocked out before {} days ago", deleted, retentionDays);
        }
    }
}
