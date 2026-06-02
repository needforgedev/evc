import 'package:flutter/material.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../account/account_screen.dart';
import '../charging/charging_screen.dart';
import '../earnings/earnings_screen.dart';
import '../home/driver_home_screen.dart';

/// Root of the Driver app once signed in — bottom nav over the main tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    DriverHomeScreen(),
    EarningsScreen(),
    ChargingScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: EvcColors.surface,
        indicatorColor: EvcColors.primary.withValues(alpha: 0.16),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Drive'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Earnings'),
          NavigationDestination(
              icon: Icon(Icons.ev_station_outlined),
              selectedIcon: Icon(Icons.ev_station),
              label: 'Charging'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Account'),
        ],
      ),
    );
  }
}