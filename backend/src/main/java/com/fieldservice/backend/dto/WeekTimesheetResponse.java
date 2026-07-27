package com.fieldservice.backend.dto;

import java.util.List;

public record WeekTimesheetResponse(List<ShiftResponse> shifts, long totalMinutes) {
}
