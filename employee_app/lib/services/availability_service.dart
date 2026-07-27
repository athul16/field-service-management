import '../core/api_client.dart';
import '../models/availability_slot.dart';

/// Handles the worker's declared availability windows.
class AvailabilityService {
  final _client = ApiClient.instance;

  Future<List<AvailabilitySlot>> fetchMySlots() async {
    final rows = await _client.get('/api/availability') as List;
    return rows.map((row) => AvailabilitySlot.fromMap(row as Map<String, dynamic>)).toList();
  }

  /// Adds one slot per day in [dates], each spanning [startTime]-[endTime].
  /// This backs the "drag a date range, then set one time range" flow used
  /// on the availability screen.
  Future<void> addSlotsForDates({
    required List<DateTime> dates,
    required TimeOfDayRange timeRange,
  }) async {
    if (dates.isEmpty) return;

    final slots = dates.map((date) {
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        timeRange.startHour,
        timeRange.startMinute,
      ).toUtc();
      final end = DateTime(
        date.year,
        date.month,
        date.day,
        timeRange.endHour,
        timeRange.endMinute,
      ).toUtc();
      return {
        'startAt': start.toIso8601String(),
        'endAt': end.toIso8601String(),
      };
    }).toList();

    await _client.post('/api/availability', body: {'slots': slots});
  }

  Future<void> deleteSlot(String id) async {
    await _client.delete('/api/availability/$id');
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
