package com.fieldservice.backend.service;

import com.fieldservice.backend.dto.WeekTimesheetResponse;
import com.fieldservice.backend.repository.ShiftRepository;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TimesheetService {

    private final ShiftRepository shiftRepository;

    public TimesheetService(ShiftRepository shiftRepository) {
        this.shiftRepository = shiftRepository;
    }

    /**
     * weekStart/weekEnd are UTC instants computed client-side — same
     * discipline as availability slots — rather than a bare LocalDate the
     * server would have to guess a timezone for. This is the exact class
     * of bug (agents.md) that already broke this app's UTC/local-time
     * handling more than once; not repeating it here.
     */
    @Transactional(readOnly = true)
    public WeekTimesheetResponse getWeek(UUID workerId, Instant weekStart, Instant weekEnd) {
        var shifts = shiftRepository.findResponsesForWeek(workerId, weekStart, weekEnd);

        long totalMinutes = shifts.stream()
                .mapToLong(shift -> Duration.between(shift.clockInAt(), shift.clockOutAt()).toMinutes())
                .sum();

        return new WeekTimesheetResponse(shifts, totalMinutes);
    }
}
