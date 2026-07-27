import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme.dart';
import '../../models/availability_slot.dart';
import '../../services/availability_service.dart';

/// Lets a worker mark whole days as available by tapping them directly on
/// the calendar — no time-of-day, no separate save step. An available day
/// turns green immediately; tapping it again un-marks it. Kept deliberately
/// simple for non-technical, low-literacy users.
class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final _availabilityService = AvailabilityService();

  DateTime _focusedDay = DateTime.now();

  List<AvailabilitySlot> _existingSlots = [];
  final Set<DateTime> _pendingDates = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _loading = true);
    try {
      final slots = await _availabilityService.fetchMySlots();
      setState(() {
        _existingSlots = slots;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Could not load your availability. Pull down to try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isAvailable(DateTime day) {
    final target = _dateOnly(day);
    return _existingSlots.any((slot) => _dateOnly(slot.startAt.toLocal()) == target);
  }

  /// Tapping a day toggles it instantly (no spinner, no network wait) —
  /// mark the whole day available, or un-mark it if it already is, so a
  /// worker can freely change their mind without hunting for a delete
  /// button elsewhere. The actual add/delete call happens in the
  /// background; a real request only shows up on screen if it fails.
  Future<void> _toggleDay(DateTime day) async {
    final date = _dateOnly(day);
    if (_pendingDates.contains(date)) return;

    final wasAvailable = _isAvailable(day);

    // Capture the real (server-assigned) ids to delete *before* the
    // optimistic update below clears them out of _existingSlots.
    final idsToDelete = _existingSlots
        .where((s) => _dateOnly(s.startAt.toLocal()) == date)
        .map((s) => s.id)
        .toList();

    final placeholder = AvailabilitySlot(
      id: 'local-${date.toIso8601String()}',
      startAt: date.toUtc(),
      endAt: date.add(const Duration(days: 1)).toUtc(),
    );

    setState(() {
      _error = null;
      _focusedDay = day;
      _pendingDates.add(date);
      if (wasAvailable) {
        _existingSlots = _existingSlots.where((s) => _dateOnly(s.startAt.toLocal()) != date).toList();
      } else {
        _existingSlots = [..._existingSlots, placeholder];
      }
    });

    try {
      if (wasAvailable) {
        await Future.wait(idsToDelete.map(_availabilityService.deleteSlot));
      } else {
        // Swap the local placeholder for the real, server-assigned slot
        // using the add call's own response — no second round trip, and
        // no risk of a slower request elsewhere clobbering this date.
        final created = await _availabilityService.addFullDayAvailability([day]);
        if (mounted) {
          setState(() {
            _existingSlots = [
              ..._existingSlots.where((s) => s.id != placeholder.id),
              ...created,
            ];
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not update that day. Try again.');
      await _loadSlots();
    } finally {
      if (mounted) setState(() => _pendingDates.remove(date));
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all available days?'),
        content: const Text('This removes every day you marked as available. You can always mark them again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _clearAll();
  }

  Future<void> _clearAll() async {
    final ids = _existingSlots.map((s) => s.id).toList();
    if (ids.isEmpty) return;

    final previous = _existingSlots;
    setState(() {
      _error = null;
      _existingSlots = [];
    });
    try {
      await Future.wait(ids.map(_availabilityService.deleteSlot));
    } catch (e) {
      if (mounted) {
        setState(() {
          _existingSlots = previous;
          _error = 'Could not clear your availability. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadSlots,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tap the days you are free to work',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Green means available. Tap a green day to remove it.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 1)),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (_) => false,
              headerStyle: const HeaderStyle(formatButtonVisible: false),
              onDaySelected: (selectedDay, focusedDay) => _toggleDay(selectedDay),
              onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) => _buildDayCell(day),
                todayBuilder: (context, day, focusedDay) => _buildDayCell(day, isToday: true),
                outsideBuilder: (context, day, focusedDay) => _buildDayCell(day, isOutside: true),
              ),
            ),
          if (!_loading && _existingSlots.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmClearAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade300),
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear All'),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, {bool isToday = false, bool isOutside = false}) {
    final available = _isAvailable(day);
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: available ? Colors.green.shade600 : Colors.transparent,
        shape: BoxShape.circle,
        border: isToday && !available ? Border.all(color: AppTheme.primary, width: 2) : null,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: available || isToday ? FontWeight.w700 : FontWeight.w400,
          color: available
              ? Colors.white
              : isOutside
                  ? Colors.grey.shade400
                  : Colors.black87,
        ),
      ),
    );
  }
}
