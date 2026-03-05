import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'badges_page.dart';
import 'goals_page.dart';
import 'history_page.dart';
import 'simulation_page.dart';
import 'transactions_page.dart';
import 'scenarios_page.dart';
import 'premium_page.dart';
import '../providers/scenario_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/transaction_provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _primaryGreen = Color(0xFF22C55E);
  static const _darkNavy = Color(0xFF0F172A);

  List<Widget> get _pages => [
        const SimulationPage(),
        const GoalsPage(),
        const _HomeTabBody(),
        const TransactionsPage(),
        const BadgesPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spendly'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _drawerTile('Profile', Icons.person_outline, () => _openPlaceholder(context, 'Profile')),
              _drawerTile('History', Icons.bar_chart, () => _openThenClose(context, const HistoryPage())),
              _drawerTile('Scenarios Library', Icons.layers_outlined, () => _openThenClose(context, const ScenariosPage())),
              _drawerTile('Premium', Icons.workspace_premium_outlined, () => _openThenClose(context, const PremiumPage())),
              _drawerTile('Rewards', Icons.card_giftcard_outlined, () => _openPlaceholder(context, 'Rewards')),
              _drawerTile('Friends', Icons.people_outline, () => _openPlaceholder(context, 'Friends')),
              _drawerTile('Partner Offers', Icons.local_offer_outlined, () => _openPlaceholder(context, 'Partner Offers')),
              _drawerTile('Settings', Icons.settings_outlined, () => _openPlaceholder(context, 'Settings')),
              _drawerTile('Help', Icons.help_outline, () => _openPlaceholder(context, 'Help')),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.grey),
                title: const Text('Sign out'),
                onTap: () async {
                  Navigator.pop(context);
                  await Supabase.instance.client.auth.signOut();
                },
              ),
            ],
          ),
        ),
      ),
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.flash_on, 'Daily'),
                _navItem(1, Icons.track_changes, 'Goals'),
                _navItem(2, Icons.home_rounded, 'Home'),
                _navItem(3, Icons.receipt_long_outlined, 'Transactions'),
                _navItem(4, Icons.emoji_events_outlined, 'Badges'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openThenClose(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _openPlaceholder(BuildContext context, String title) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(child: Text('$title — Coming soon')),
        ),
      ),
    );
  }

  Widget _drawerTile(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _darkNavy),
      title: Text(label),
      onTap: onTap,
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final selected = _index == i;
    return InkWell(
      onTap: () => setState(() => _index = i),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: selected ? _primaryGreen : const Color(0xFF9CA3AF)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? _primaryGreen : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home tab: dark hero (today's budget), 3 stat cards, scenario cards.
class _HomeTabBody extends ConsumerWidget {
  const _HomeTabBody();

  static const _primaryGreen = Color(0xFF22C55E);
  static const _darkNavy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalProvider);
    ref.watch(transactionListProvider); // rebuild when transactions change
    final packs = ref.watch(scenarioPacksProvider);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final daySpent = ref.read(transactionListProvider.notifier).totalBetween(startOfDay, endOfDay);
    final budgetCents = goal?.amountCents ?? 50000; // ₱500 default
    final spentCents = goal?.spentCents ?? (daySpent > 0 ? daySpent : 0);
    final remaining = (budgetCents - spentCents).clamp(0, budgetCents);
    final progress = budgetCents == 0 ? 0.0 : (spentCents / budgetCents).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Hero: today's budget
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _darkNavy,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's budget",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₱${(budgetCents / 100).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Spent ₱${(spentCents / 100).toStringAsFixed(0)} · Remaining ₱${(remaining / 100).toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(_primaryGreen),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Three stat cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: '3 days',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                label: 'Spendly Score',
                value: '72',
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.people_rounded,
                label: 'Friends rank',
                value: '#2',
                color: _primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Scenarios',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _darkNavy,
              ),
        ),
        const SizedBox(height: 12),
        ...packs.asMap().entries.map((e) {
          final pack = e.value;
          final isActive = pack.modules.any((m) => !m.completed);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isActive ? _primaryGreen.withOpacity(0.5) : const Color(0xFFE5E7EB),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive ? _primaryGreen.withOpacity(0.15) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isActive ? Icons.play_circle_filled : Icons.lock_outline,
                    color: isActive ? _primaryGreen : Colors.grey,
                    size: 28,
                  ),
                ),
                title: Text(
                  pack.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? _darkNavy : Colors.grey.shade700,
                  ),
                ),
                subtitle: Text(
                  pack.topic,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.grey.shade600 : Colors.grey,
                  ),
                ),
                trailing: isActive
                    ? const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF))
                    : null,
                onTap: isActive
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScenariosPage(),
                          ),
                        )
                    : null,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
