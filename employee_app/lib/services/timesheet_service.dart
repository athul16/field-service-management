import '../core/api_client.dart';
import '../models/shift.dart';

/// Computes weekly/monthly hours from completed shifts for the timesheet
/// screen. The backend endpoint is a plain date-range query (`/api/timesheet/week`
/// with a `weekStart`/`weekEnd` pair) — it doesn't actually care whether that
/// range spans a week or a month, so both views reuse it as-is rather than
/// needing a separate backend endpoint.
class TimesheetService {
  final _client = ApiClient.instance;

  /// Completed shifts for the week containing [anyDayInWeek] (Mon-Sun).
  Future<List<Shift>> fetchShiftsForWeek(DateTime anyDayInWeek) async {
    final weekStart = _startOfWeek(anyDayInWeek);
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _fetchShifts(weekStart, weekEnd);
  }

  /// Completed shifts for the calendar month containing [anyDayInMonth].
  Future<List<Shift>> fetchShiftsForMonth(DateTime anyDayInMonth) async {
    final monthStart = DateTime(anyDayInMonth.year, anyDayInMonth.month);
    final monthEnd = DateTime(anyDayInMonth.year, anyDayInMonth.month + 1);
    return _fetchShifts(monthStart, monthEnd);
  }

  Future<List<Shift>> _fetchShifts(DateTime rangeStart, DateTime rangeEnd) async {
    final response = await _client.get('/api/timesheet/week', query: {
      'weekStart': rangeStart.toUtc().toIso8601String(),
      'weekEnd': rangeEnd.toUtc().toIso8601String(),
    }) as Map<String, dynamic>;

    final shifts = response['shifts'] as List;
    return shifts.map((row) => Shift.fromMap(row as Map<String, dynamic>)).toList();
  }

  Duration totalHours(List<Shift> shifts) {
    return shifts.fold(Duration.zero, (total, shift) {
      final worked = shift.workedDuration;
      return worked == null ? total : total + worked;
    });
  }

  DateTime _startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - DateTime.monday;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }
}
