import 'dart:io';

import '../core/api_client.dart';
import '../models/shift.dart';
import '../models/site.dart';

/// Handles everything related to clocking in/out at a site. The backend
/// infers the current worker from the JWT on every call (and verifies
/// site assignment / shift ownership itself), so nothing here needs to
/// track or send a worker id.
class ClockService {
  final _client = ApiClient.instance;

  /// Sites the current worker has been assigned to (via the owner dashboard).
  Future<List<Site>> fetchAssignedSites() async {
    final rows = await _client.get('/api/sites/assigned') as List;
    return rows.map((row) => Site.fromMap(row as Map<String, dynamic>)).toList();
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

  /// Clocking out requires a progress photo, per the project spec.
  Future<Shift> clockOut({
    required String shiftId,
    required File progressPhoto,
  }) async {
    final row = await _client.postMultipart(
      '/api/shifts/$shiftId/clock-out',
      fieldName: 'photo',
      file: progressPhoto,
    );
    return Shift.fromMap(row as Map<String, dynamic>);
  }
}
