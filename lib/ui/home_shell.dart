import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'badges_page.dart';
import 'goals_page.dart';
import 'history_page.dart';
import 'simulation_page.dart';
import 'goal_setup_page.dart';
import 'transactions_page.dart';
import 'receipts_page.dart';
import 'scenarios_page.dart';
import 'premium_page.dart';
import 'valuation_page.dart';

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
    TransactionsPage(),
    ReceiptsPage(),
    ScenariosPage(),
    PremiumPage(),
    ValuationPage(),
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
            tooltip: 'Set Spend Goal',
            icon: const Icon(Icons.track_changes),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GoalSetupPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
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
            icon: Icon(Icons.flash_on),
            label: 'Daily',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card),
            label: 'Transact',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Resibo',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            label: 'Scenarios',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            label: 'Premium',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            label: 'Value',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Badges',
          ),
        ],
      ),
    );
  }
}

