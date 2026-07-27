import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/shift.dart';

/// Computes weekly hours from completed shifts for the timesheet screen.
class TimesheetService {
  final SupabaseClient _client = SupabaseConfig.client;

  String get _workerId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No signed-in worker.');
    return id;
  }

  /// Completed shifts for the week containing [anyDayInWeek] (Mon-Sun).
  Future<List<Shift>> fetchShiftsForWeek(DateTime anyDayInWeek) async {
    final weekStart = _startOfWeek(anyDayInWeek);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final rows = await _client
        .from('shifts')
        .select()
        .eq('worker_id', _workerId)
        .eq('status', 'completed')
        .gte('clock_in_at', weekStart.toUtc().toIso8601String())
        .lt('clock_in_at', weekEnd.toUtc().toIso8601String())
        .order('clock_in_at');

    return (rows as List).map((row) => Shift.fromMap(row)).toList();
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
