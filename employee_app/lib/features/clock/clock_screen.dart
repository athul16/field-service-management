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
      setState(() => _error = 'Could not start shift. Try again.');
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
      setState(() => _error = 'Could not end shift. Try again.');
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

  // A fixed, recognizable color per site (same site = same color every time)
  // stands in for a real site photo — the app has no per-site imagery, and a
  // random icon per site would imply a meaning ("warehouse" vs "store") that
  // isn't actually there. Consistent icon + consistent color lets a worker
  // recognize "my site" by shape/color alone, without needing to read the name.
  static const _siteColors = [
    Color(0xFF1565C0), // blue
    Color(0xFF2E7D32), // green
    Color(0xFFEF6C00), // orange
    Color(0xFF6A1B9A), // purple
    Color(0xFFAD1457), // pink
    Color(0xFF00695C), // teal
  ];

  Color _colorForSite(Site site) => _siteColors[site.id.hashCode.abs() % _siteColors.length];

  List<Widget> _buildClockInForm() {
    return [
      const Text('Select your work site', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      if (_sites.isEmpty)
        const Text(
          "You don't have any assigned sites yet. Check back soon.",
          style: TextStyle(fontSize: 16),
        )
      else
        ..._sites.map(_buildSiteButton),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 72,
        child: ElevatedButton.icon(
          onPressed: (_submitting || _selectedSite == null) ? null : _clockIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.login, size: 32),
          label: Text(
            _submitting ? 'Starting shift...' : '🟢 Start Shift',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ];
  }

  Widget _buildSiteButton(Site site) {
    final selected = _selectedSite?.id == site.id;
    final color = _colorForSite(site);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? color.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _selectedSite = selected ? null : site),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 3 : 1),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: color,
                  child: const Icon(Icons.location_on, size: 34, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      if (site.projectName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          site.projectName!,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color,
                    child: const Icon(Icons.check, size: 20, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActiveShift(Shift shift) {
    final elapsed = DateTime.now().difference(shift.clockInAt);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    final localClockIn = shift.clockInAt.toLocal();

    // The active shift only carries a siteId/siteName — cross-reference the
    // already-fetched assigned-sites list to also show the project name,
    // rather than adding a new backend field just for this display.
    final site = _sites.where((s) => s.id == shift.siteId).firstOrNull;
    final projectName = site?.projectName;

    return [
      Card(
        color: Colors.green.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.green.shade600,
                child: const Icon(Icons.access_time_filled, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Shift in progress',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              if (shift.siteName != null) ...[
                const SizedBox(height: 4),
                Text(
                  projectName != null ? '${shift.siteName} · $projectName' : shift.siteName!,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '${hours}h ${minutes}m',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.green.shade800),
              ),
              const SizedBox(height: 4),
              Text(
                'Started at ${localClockIn.hour.toString().padLeft(2, '0')}:${localClockIn.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 28),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Ending your shift needs a quick photo of your work.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 72,
        child: ElevatedButton.icon(
          onPressed: _submitting ? null : _clockOut,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.camera_alt, size: 32),
          label: Text(
            _submitting ? 'Ending shift...' : '🔴 End Shift',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ];
  }
}
