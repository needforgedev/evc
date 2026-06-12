import 'package:flutter/material.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../l10n/app_strings.dart';
import '../drivers/drivers_screen.dart';
import '../live/live_map_screen.dart';
import '../more/more_screen.dart';
import '../overview/overview_screen.dart';
import '../trips/trips_screen.dart';

/// Root of the Admin app once signed in — bottom nav over the ops sections.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    OverviewScreen(),
    LiveMapScreen(),
    DriversScreen(),
    TripsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tr = AppStrings.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: EvcColors.surface,
        indicatorColor: EvcColors.primary.withValues(alpha: 0.16),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: tr.overview),
          NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map),
              label: tr.live),
          NavigationDestination(
              icon: const Icon(Icons.badge_outlined),
              selectedIcon: const Icon(Icons.badge),
              label: tr.drivers),
          NavigationDestination(
              icon: const Icon(Icons.alt_route_outlined),
              selectedIcon: const Icon(Icons.alt_route),
              label: tr.trips),
          NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view),
              label: tr.more),
        ],
      ),
    );
  }
}