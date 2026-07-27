import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/shift.dart';
import '../../models/site.dart';
import '../../services/clock_service.dart';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  final _clockService = ClockService();
  final _imagePicker = ImagePicker();
  Timer? _elapsedTicker;

  bool _loading = true;
  bool _submitting = false;
  String? _error;

  List<Site> _sites = [];
  Site? _selectedSite;
  Shift? _activeShift;

  @override
  void initState() {
    super.initState();
    _load();
    // Elapsed time is computed from DateTime.now() at build time, so
    // re-triggering a build every 30s is what keeps it ticking on screen.
    _elapsedTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_activeShift != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _elapsedTicker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _clockService.fetchAssignedSites(),
        _clockService.fetchActiveShift(),
      ]);
      setState(() {
        _sites = results[0] as List<Site>;
        _activeShift = results[1] as Shift?;
      });
    } catch (e) {
      setState(() => _error = 'Could not load your sites. Pull down to try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _clockIn() async {
    if (_selectedSite == null) {
      setState(() => _error = 'Pick a work site first.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final shift = await _clockService.clockIn(_selectedSite!.id);
      setState(() => _activeShift = shift);
    } catch (e) {
      setState(() => _error = 'Could not clock in. Try again.');
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _clockOut() async {
    final shift = _activeShift;
    if (shift == null) return;

    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (photo == null) return; // Worker cancelled — clock-out requires a photo.

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _clockService.clockOut(
        shiftId: shift.id,
        progressPhoto: File(photo.path),
      );
      setState(() => _activeShift = null);
    } catch (e) {
      setState(() => _error = 'Could not clock out. Try again.');
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_activeShift != null) ..._buildActiveShift(_activeShift!),
          if (_activeShift == null) ..._buildClockInForm(),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildClockInForm() {
    return [
      const Text('Select your work site', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      if (_sites.isEmpty)
        const Text("You don't have any assigned sites yet. Check back soon.")
      else
        DropdownButtonFormField<Site>(
          initialValue: _selectedSite,
          items: _sites
              .map((site) => DropdownMenuItem(
                    value: site,
                    child: Text('${site.name} — ${site.projectName ?? ''}'),
                  ))
              .toList(),
          onChanged: (site) => setState(() => _selectedSite = site),
          decoration: const InputDecoration(labelText: 'Work site'),
        ),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: _submitting ? null : _clockIn,
        icon: const Icon(Icons.login),
        label: Text(_submitting ? 'Clocking in...' : 'Clock In'),
      ),
    ];
  }

  List<Widget> _buildActiveShift(Shift shift) {
    final elapsed = DateTime.now().difference(shift.clockInAt);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    final localClockIn = shift.clockInAt.toLocal();

    return [
      Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You are clocked in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Started at ${localClockIn.hour.toString().padLeft(2, '0')}:${localClockIn.minute.toString().padLeft(2, '0')}'),
              Text('Elapsed: ${hours}h ${minutes}m'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Clocking out requires a quick progress photo.',
        style: TextStyle(fontSize: 14, color: Colors.black54),
      ),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: _submitting ? null : _clockOut,
        icon: const Icon(Icons.camera_alt),
        label: Text(_submitting ? 'Clocking out...' : 'Take Photo & Clock Out'),
      ),
    ];
  }
}
