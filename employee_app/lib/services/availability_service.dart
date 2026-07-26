import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/availability_slot.dart';

/// Handles the worker's declared availability windows.
class AvailabilityService {
  final SupabaseClient _client = SupabaseConfig.client;

  String get _workerId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No signed-in worker.');
    return id;
  }

  Future<List<AvailabilitySlot>> fetchMySlots() async {
    final rows = await _client
        .from('availability_slots')
        .select()
        .eq('worker_id', _workerId)
        .order('start_at');

    return (rows as List)
        .map((row) => AvailabilitySlot.fromMap(row))
        .toList();
  }

  /// Adds one slot per day in [dates], each spanning [startTime]-[endTime].
  /// This backs the "drag a date range, then set one time range" flow used
  /// on the availability screen.
  Future<void> addSlotsForDates({
    required List<DateTime> dates,
    required TimeOfDayRange timeRange,
  }) async {
    final inserts = dates.map((date) {
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        timeRange.startHour,
        timeRange.startMinute,
      );
      final end = DateTime(
        date.year,
        date.month,
        date.day,
        timeRange.endHour,
        timeRange.endMinute,
      );
      return {
        'worker_id': _workerId,
        'start_at': start.toIso8601String(),
        'end_at': end.toIso8601String(),
      };
    }).toList();

    if (inserts.isEmpty) return;
    await _client.from('availability_slots').insert(inserts);
  }

  Future<void> deleteSlot(String id) async {
    await _client.from('availability_slots').delete().eq('id', id);
  }
}

/// Small helper so the UI can pass a simple start/end time pair without
/// pulling in Flutter's TimeOfDay into the service layer.
class TimeOfDayRange {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const TimeOfDayRange({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });
}
