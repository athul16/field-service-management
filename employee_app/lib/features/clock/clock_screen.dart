import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/assignment.dart';
import '../../models/shift.dart';
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

  List<Assignment> _assignments = [];
  Shift? _activeShift;

  static const _maxClockOutPhotos = 3;
  // Resized/recompressed at selection time (not after) so 3 attachments stay
  // light on mobile data and on-disk storage without a separate compression step.
  static const _photoMaxDimension = 1024.0;
  static const _photoQuality = 60;

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
        _clockService.fetchMyAssignments(),
        _clockService.fetchActiveShift(),
      ]);
      setState(() {
        _assignments = results[0] as List<Assignment>;
        _activeShift = results[1] as Shift?;
      });
    } catch (e) {
      setState(() => _error = 'Could not load your sites. Pull down to try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _clockIn(Assignment assignment) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final shift = await _clockService.clockIn(assignment.siteId);
      setState(() => _activeShift = shift);
    } catch (e) {
      setState(() => _error = 'Could not start shift. Try again.');
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _clockOut(List<File> photos) async {
    final shift = _activeShift;
    if (shift == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _clockService.clockOut(shiftId: shift.id, progressPhotos: photos);
      setState(() => _activeShift = null);
    } catch (e) {
      setState(() => _error = 'Could not end shift. Try again.');
    } finally {
      setState(() => _submitting = false);
    }
  }

  /// A small "camera or gallery" chooser — attaching finished-work photos
  /// doesn't need to be a live camera capture, so gallery photos are just
  /// as valid as a fresh one.
  Future<void> _pickPhoto(void Function(File) onPicked) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final photo = await _imagePicker.pickImage(
      source: source,
      maxWidth: _photoMaxDimension,
      maxHeight: _photoMaxDimension,
      imageQuality: _photoQuality,
    );
    if (photo != null) onPicked(File(photo.path));
  }

  Future<void> _showEndShiftSheet() async {
    final photos = <File>[];
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add photos to end shift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Attach 1 to $_maxClockOutPhotos photos of your finished work.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(_maxClockOutPhotos, (i) {
                      final hasPhoto = i < photos.length;
                      return Padding(
                        padding: EdgeInsets.only(right: i < _maxClockOutPhotos - 1 ? 12 : 0),
                        child: hasPhoto
                            ? Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(photos[i], width: 88, height: 88, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: GestureDetector(
                                      onTap: () => setSheetState(() => photos.removeAt(i)),
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.black87,
                                        child: Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _pickPhoto((file) => setSheetState(() => photos.add(file))),
                                child: Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                  ),
                                  child: Icon(Icons.add_a_photo, color: Colors.grey.shade400, size: 28),
                                ),
                              ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: photos.isEmpty ? null : () => Navigator.pop(sheetContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('🔴 End Shift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (confirmed == true) {
      await _clockOut(photos);
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
          if (_assignments.isEmpty)
            const Text(
              "You don't have any assigned sites yet. Check back soon.",
              style: TextStyle(fontSize: 16),
            )
          else
            ..._assignments.map(_buildAssignmentCard),
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

  Color _colorForSite(String siteId) => _siteColors[siteId.hashCode.abs() % _siteColors.length];

  /// Shifts are tracked per-site on the backend, not per-project, so a
  /// worker with two assignments at the same site sees both cards go
  /// "active" together when either one's Start button is tapped — that's
  /// not a bug, it's genuinely the same underlying shift either card can end.
  Widget _buildAssignmentCard(Assignment assignment) {
    final isActive = _activeShift != null && _activeShift!.siteId == assignment.siteId;
    final blockedByOtherShift = _activeShift != null && !isActive;
    final color = _colorForSite(assignment.siteId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: blockedByOtherShift ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? Colors.green.shade400 : Colors.grey.shade300,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color,
                child: const Icon(Icons.location_on, size: 30, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.siteName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      assignment.projectName,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      assignment.siteAddress,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 8),
                      Text(
                        _elapsedLabel(_activeShift!.clockInAt),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green.shade800),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildToggleButton(assignment, isActive, blockedByOtherShift),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(Assignment assignment, bool isActive, bool disabled) {
    // A fixed width keeps the Row's constraints bounded (ElevatedButton's own
    // maximumSize otherwise resolves to infinite and upsets RenderFlex) and
    // stops the button from jumping in size between "Start" and "End".
    if (isActive) {
      return SizedBox(
        width: 92,
        height: 44,
        child: ElevatedButton(
          onPressed: _submitting ? null : _showEndShiftSheet,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: const Text('🔴 End', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
    }
    return SizedBox(
      width: 92,
      height: 44,
      child: ElevatedButton(
        onPressed: (_submitting || disabled) ? null : () => _clockIn(assignment),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: const Text('🟢 Start', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  String _elapsedLabel(DateTime clockInAt) {
    final elapsed = DateTime.now().difference(clockInAt);
    return 'In progress · ${elapsed.inHours}h ${elapsed.inMinutes % 60}m';
  }
}
