import 'package:flutter/material.dart';
import 'package:radix_icons/radix_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'badges_page.dart';
import 'goals_page.dart';
import 'history_page.dart';
import 'simulation_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    SimulationPage(),
    GoalsPage(),
    HistoryPage(),
    BadgesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spendly'),
        actions: [
          IconButton(
            icon: const Icon(RadixIcons.Exit),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(RadixIcons.Lightning_Bolt),
            label: 'Daily',
          ),
          NavigationDestination(
            icon: Icon(RadixIcons.Target),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(RadixIcons.Bar_Chart),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(RadixIcons.Star),
            label: 'Badges',
          ),
        ],
      ),
    );
  }
}

