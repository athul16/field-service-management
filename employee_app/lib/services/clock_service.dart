import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/shift.dart';
import '../models/site.dart';

/// Handles everything related to clocking in/out at a site.
class ClockService {
  final SupabaseClient _client = SupabaseConfig.client;
  static const _photoBucket = 'shift-photos';

  String get _workerId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No signed-in worker.');
    return id;
  }

  /// Sites the current worker has been assigned to (via the owner dashboard).
  Future<List<Site>> fetchAssignedSites() async {
    final rows = await _client
        .from('assignments')
        .select('sites(id, project_id, name, address, projects(name))')
        .eq('worker_id', _workerId);

    return (rows as List)
        .map((row) => Site.fromMap(row['sites'] as Map<String, dynamic>))
        .toList();
  }

  /// The worker's currently open shift, if any (they haven't clocked out yet).
  Future<Shift?> fetchActiveShift() async {
    final row = await _client
        .from('shifts')
        .select()
        .eq('worker_id', _workerId)
        .eq('status', 'in_progress')
        .maybeSingle();

    return row == null ? null : Shift.fromMap(row);
  }

  Future<Shift> clockIn(String siteId) async {
    final row = await _client
        .from('shifts')
        .insert({
          'worker_id': _workerId,
          'site_id': siteId,
          'status': 'in_progress',
        })
        .select()
        .single();

    return Shift.fromMap(row);
  }

  /// Clocking out requires a progress photo, per the project spec.
  Future<Shift> clockOut({
    required String shiftId,
    required File progressPhoto,
  }) async {
    final fileName =
        '$_workerId/${shiftId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from(_photoBucket).upload(fileName, progressPhoto);
    final photoUrl = _client.storage.from(_photoBucket).getPublicUrl(fileName);

    final row = await _client
        .from('shifts')
        .update({
          'clock_out_at': DateTime.now().toUtc().toIso8601String(),
          'clock_out_photo_url': photoUrl,
          'status': 'completed',
        })
        .eq('id', shiftId)
        .select()
        .single();

    return Shift.fromMap(row);
  }
}
