package com.fieldservice.backend.controller;

import com.fieldservice.backend.dto.WeekTimesheetResponse;
import com.fieldservice.backend.entity.Profile;
import com.fieldservice.backend.service.TimesheetService;
import java.time.Instant;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TimesheetController {

    private final TimesheetService timesheetService;

    public TimesheetController(TimesheetService timesheetService) {
        this.timesheetService = timesheetService;
    }

    /** weekStart/weekEnd are UTC instants computed client-side — see TimesheetService's note on why. */
    @GetMapping("/api/timesheet/week")
    public WeekTimesheetResponse week(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant weekStart,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant weekEnd,
            @AuthenticationPrincipal Profile currentUser) {
        return timesheetService.getWeek(currentUser.getId(), weekStart, weekEnd);
    }
}
