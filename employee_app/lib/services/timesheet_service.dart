import '../core/api_client.dart';
import '../models/shift.dart';

/// Computes weekly hours from completed shifts for the timesheet screen.
class TimesheetService {
  final _client = ApiClient.instance;

  /// Completed shifts for the week containing [anyDayInWeek] (Mon-Sun).
  Future<List<Shift>> fetchShiftsForWeek(DateTime anyDayInWeek) async {
    final weekStart = _startOfWeek(anyDayInWeek);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final response = await _client.get('/api/timesheet/week', query: {
      'weekStart': weekStart.toUtc().toIso8601String(),
      'weekEnd': weekEnd.toUtc().toIso8601String(),
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
