import 'package:flutter/material.dart';

import '../../models/shift.dart';
import '../../services/timesheet_service.dart';

enum _TimesheetView { week, month }

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  final _timesheetService = TimesheetService();

  _TimesheetView _view = _TimesheetView.week;
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
    final shifts = _view == _TimesheetView.week
        ? await _timesheetService.fetchShiftsForWeek(_referenceDay)
        : await _timesheetService.fetchShiftsForMonth(_referenceDay);
    setState(() {
      _shifts = shifts;
      _loading = false;
    });
  }

  void _changeView(_TimesheetView view) {
    if (view == _view) return;
    setState(() => _view = view);
    _load();
  }

  void _step(int delta) {
    setState(() {
      _referenceDay = _view == _TimesheetView.week
          ? _referenceDay.add(Duration(days: 7 * delta))
          : DateTime(_referenceDay.year, _referenceDay.month + delta, 1);
    });
    _load();
  }

  Future<void> _pickWeek() async {
    final thisMonday = _startOfWeek(DateTime.now());
    // Past 12 weeks, most recent first — same tap-a-row pattern as the
    // month picker, so both views offer an equally quick way to jump back
    // instead of only stepping one week/month at a time via the arrows.
    final options = List.generate(12, (i) => thisMonday.subtract(Duration(days: 7 * i)));

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select a week', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final monday in options)
              ListTile(
                title: Text(
                  'Week of ${monday.month}/${monday.day}',
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () => Navigator.pop(context, monday),
              ),
          ],
        ),
      ),
    );

    if (picked == null) return;
    setState(() => _referenceDay = picked);
    _load();
  }

  DateTime _startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    // Past 12 months, most recent first — a simple tap-a-month list rather
    // than a full date-picker dialog, since only the month/year matter here.
    final options = List.generate(12, (i) => DateTime(now.year, now.month - i, 1));

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select a month', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final month in options)
              ListTile(
                title: Text(_monthYearLabel(month), style: const TextStyle(fontSize: 16)),
                onTap: () => Navigator.pop(context, month),
              ),
          ],
        ),
      ),
    );

    if (picked == null) return;
    setState(() => _referenceDay = picked);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = _timesheetService.totalHours(_shifts);
    final periodLabel = _view == _TimesheetView.week ? 'week' : 'month';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<_TimesheetView>(
            segments: const [
              ButtonSegment(value: _TimesheetView.week, label: Text('Week'), icon: Icon(Icons.view_week)),
              ButtonSegment(value: _TimesheetView.month, label: Text('Month'), icon: Icon(Icons.calendar_month)),
            ],
            selected: {_view},
            onSelectionChanged: (selection) => _changeView(selection.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _step(-1),
              ),
              InkWell(
                onTap: _view == _TimesheetView.week ? _pickWeek : _pickMonth,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _view == _TimesheetView.week ? 'Week of ${_weekStartLabel()}' : _monthYearLabel(_referenceDay),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _step(1),
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
              'Total this $periodLabel: ${total.inHours}h ${total.inMinutes % 60}m',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _shifts.isEmpty
                  ? Center(child: Text('No completed shifts this $periodLabel.'))
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
    final monday = _startOfWeek(_referenceDay);
    return '${monday.month}/${monday.day}';
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _monthYearLabel(DateTime d) => '${_monthNames[d.month - 1]} ${d.year}';

  String _dayLabel(DateTime d) => '${d.month}/${d.day}';

  String _timeLabel(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
