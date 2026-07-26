import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../availability/availability_screen.dart';
import '../clock/clock_screen.dart';
import '../timesheet/timesheet_screen.dart';

/// Bottom-nav shell shown once a worker is signed in.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    ClockScreen(),
    AvailabilityScreen(),
    TimesheetScreen(),
  ];

  static const _titles = ['Clock In / Out', 'Availability', 'Timesheet'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.access_time), label: 'Clock'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Availability'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Timesheet'),
        ],
      ),
    );
  }
}
