import 'package:flutter/material.dart';

import '../../models/shift.dart';
import '../../services/timesheet_service.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  final _timesheetService = TimesheetService();

  DateTime _referenceDay = DateTime.now();
  List<Shift> _shifts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final shifts = await _timesheetService.fetchShiftsForWeek(_referenceDay);
    setState(() {
      _shifts = shifts;
      _loading = false;
    });
  }

  void _changeWeek(int deltaWeeks) {
    setState(() => _referenceDay = _referenceDay.add(Duration(days: 7 * deltaWeeks)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = _timesheetService.totalHours(_shifts);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeWeek(-1),
              ),
              Text(
                'Week of ${_weekStartLabel()}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Total this week: ${total.inHours}h ${total.inMinutes % 60}m',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _shifts.isEmpty
                  ? const Center(child: Text('No completed shifts this week.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _shifts.length,
                      itemBuilder: (context, index) {
                        final shift = _shifts[index];
                        final worked = shift.workedDuration!;
                        return Card(
                          child: ListTile(
                            title: Text(_dayLabel(shift.clockInAt.toLocal())),
                            subtitle: Text(
                              '${_timeLabel(shift.clockInAt.toLocal())} – ${_timeLabel(shift.clockOutAt!.toLocal())}',
                            ),
                            trailing: Text('${worked.inHours}h ${worked.inMinutes % 60}m'),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _weekStartLabel() {
    final daysFromMonday = _referenceDay.weekday - DateTime.monday;
    final monday = _referenceDay.subtract(Duration(days: daysFromMonday));
    return '${monday.month}/${monday.day}';
  }

  String _dayLabel(DateTime d) => '${d.month}/${d.day}';

  String _timeLabel(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
