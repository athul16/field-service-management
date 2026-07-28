import 'dart:io';

import '../core/api_client.dart';
import '../models/assignment.dart';
import '../models/shift.dart';

/// Handles everything related to clocking in/out at a site. The backend
/// infers the current worker from the JWT on every call (and verifies
/// site assignment / shift ownership itself), so nothing here needs to
/// track or send a worker id.
class ClockService {
  final _client = ApiClient.instance;

  /// The current worker's own assignments — one per (site, project) pair, since a site can now
  /// host more than one project and a worker can be assigned to more than one at the same site.
  Future<List<Assignment>> fetchMyAssignments() async {
    final rows = await _client.get('/api/assignments') as List;
    return rows.map((row) => Assignment.fromMap(row as Map<String, dynamic>)).toList();
  }

  /// The worker's currently open shift, if any (they haven't clocked out yet).
  Future<Shift?> fetchActiveShift() async {
    final row = await _client.get('/api/shifts/active');
    return row == null ? null : Shift.fromMap(row as Map<String, dynamic>);
  }

  Future<Shift> clockIn(String siteId) async {
    final row = await _client.post('/api/shifts/clock-in', body: {'siteId': siteId});
    return Shift.fromMap(row as Map<String, dynamic>);
  }

  /// Clocking out requires 1-3 progress photos, per the project spec.
  Future<Shift> clockOut({
    required String shiftId,
    required List<File> progressPhotos,
  }) async {
    final row = await _client.postMultipart(
      '/api/shifts/$shiftId/clock-out',
      fieldName: 'photos',
      files: progressPhotos,
    );
    return Shift.fromMap(row as Map<String, dynamic>);
  }
}
