import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/availability_slot.dart';
import '../../services/availability_service.dart';

/// Lets a worker mark availability by dragging to select a range of days
/// on the calendar, then choosing one start/end time that applies to every
/// selected day. Kept deliberately simple for non-technical users.
class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final _availabilityService = AvailabilityService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  List<AvailabilitySlot> _existingSlots = [];
  bool _loading = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _loading = true);
    try {
      final slots = await _availabilityService.fetchMySlots();
      setState(() => _existingSlots = slots);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<DateTime> get _selectedDates {
    if (_rangeStart == null) return [];
    final end = _rangeEnd ?? _rangeStart!;
    final days = end.difference(_rangeStart!).inDays;
    return List.generate(
      days + 1,
      (i) => DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day).add(Duration(days: i)),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _saveAvailability() async {
    if (_rangeStart == null) {
      setState(() => _message = 'Drag across the calendar to pick your available days.');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await _availabilityService.addSlotsForDates(
        dates: _selectedDates,
        timeRange: TimeOfDayRange(
          startHour: _startTime.hour,
          startMinute: _startTime.minute,
          endHour: _endTime.hour,
          endMinute: _endTime.minute,
        ),
      );
      setState(() {
        _rangeStart = null;
        _rangeEnd = null;
        _message = 'Availability saved.';
      });
      await _loadSlots();
    } catch (e) {
      setState(() => _message = 'Could not save availability. Try again.');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteSlot(AvailabilitySlot slot) async {
    await _availabilityService.deleteSlot(slot.id);
    await _loadSlots();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Drag across the days you can work',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 1)),
          lastDay: DateTime.now().add(const Duration(days: 90)),
          focusedDay: _focusedDay,
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          rangeSelectionMode: RangeSelectionMode.toggledOn,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _rangeStart = selectedDay;
              _rangeEnd = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onRangeSelected: (start, end, focusedDay) {
            setState(() {
              _rangeStart = start;
              _rangeEnd = end ?? start;
              _focusedDay = focusedDay;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickTime(isStart: true),
                child: Text('From ${_startTime.format(context)}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickTime(isStart: false),
                child: Text('To ${_endTime.format(context)}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _saving ? null : _saveAvailability,
          child: Text(_saving ? 'Saving...' : 'Save Availability'),
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 32),
        const Divider(),
        const Text('Your upcoming availability', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (!_loading && _existingSlots.isEmpty) const Text('No availability added yet.'),
        for (final slot in _existingSlots)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_formatSlot(slot)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteSlot(slot),
            ),
          ),
      ],
    );
  }

  String _formatSlot(AvailabilitySlot slot) {
    final date = '${slot.startAt.month}/${slot.startAt.day}';
    final start = TimeOfDay.fromDateTime(slot.startAt).format(context);
    final end = TimeOfDay.fromDateTime(slot.endAt).format(context);
    return '$date · $start – $end';
  }
}
