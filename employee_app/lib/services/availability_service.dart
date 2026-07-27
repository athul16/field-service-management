import '../core/api_client.dart';
import '../models/availability_slot.dart';

/// Handles the worker's declared availability windows.
class AvailabilityService {
  final _client = ApiClient.instance;

  Future<List<AvailabilitySlot>> fetchMySlots() async {
    final rows = await _client.get('/api/availability') as List;
    return rows.map((row) => AvailabilitySlot.fromMap(row as Map<String, dynamic>)).toList();
  }

  /// Marks each day in [dates] as fully available — no time-of-day concept
  /// for the worker at all, just "free that whole day". Represented in the
  /// database as a slot spanning local midnight to the next local midnight,
  /// since `availability_slots` still stores a start/end timestamp range;
  /// that's an implementation detail this app's UI no longer exposes.
  /// Returns the created slots (with their real server-assigned ids)
  /// straight from the response — the caller needs those ids for a later
  /// delete, and a separate follow-up fetch would just be a second round
  /// trip that risks racing a second, faster toggle elsewhere.
  Future<List<AvailabilitySlot>> addFullDayAvailability(List<DateTime> dates) async {
    if (dates.isEmpty) return [];

    final slots = dates.map((date) {
      final start = DateTime(date.year, date.month, date.day).toUtc();
      final end = DateTime(date.year, date.month, date.day).add(const Duration(days: 1)).toUtc();
      return {
        'startAt': start.toIso8601String(),
        'endAt': end.toIso8601String(),
      };
    }).toList();

    final rows = await _client.post('/api/availability', body: {'slots': slots}) as List;
    return rows.map((row) => AvailabilitySlot.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<void> deleteSlot(String id) async {
    await _client.delete('/api/availability/$id');
  }
}
