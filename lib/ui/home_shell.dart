import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'badges_page.dart';
import 'goals_page.dart';
import 'history_page.dart';
import 'simulation_page.dart';
import 'transactions_page.dart';
import 'scenarios_page.dart';
import 'premium_page.dart';
import 'settings_page.dart';
import 'ai_assistant_page.dart';
import '../providers/scenario_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/simulation_provider.dart';
import 'widgets/interactive_widgets.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final simState = ref.watch(simulationProvider);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                      bottom: BorderSide(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.1),
                          width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                        width: 32,
                        height: 24,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            image: const DecorationImage(
                                image: NetworkImage(
                                    'https://flagcdn.com/w40/ph.png'),
                                fit: BoxFit.cover))),
                    const Spacer(),
                    _topStat(
                        icon: Icons.local_fire_department_rounded,
                        value: simState.streakDays.toString(),
                        color: const Color(0xFFC0FF00)),
                    const SizedBox(width: 16),
                    _topStat(
                        icon: Icons.diamond,
                        value: '500',
                        color: const Color(0xFF6A5AE0)),
                    const SizedBox(width: 16),
                    _topStat(
                        icon: Icons.favorite,
                        value: '5',
                        color: const Color(0xFFFF4B4B)),
                    const SizedBox(width: 12),
                    Builder(
                        builder: (ctx) => GestureDetector(
                            onTap: () => Scaffold.of(ctx).openEndDrawer(),
                            child: Icon(Icons.menu,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 26))),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              DrawerHeader(
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.1),
                              width: 1))),
                  child: Text('Menu',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface))),
              _drawerTile('Profile', Icons.person_outline,
                  () => Navigator.pop(context)),
              _drawerTile('History', Icons.bar_chart,
                  () => _openThenClose(context, const HistoryPage())),
              _drawerTile('Premium', Icons.workspace_premium_outlined,
                  () => _openThenClose(context, const PremiumPage())),
              _drawerTile('Settings', Icons.settings_outlined,
                  () => _openThenClose(context, const SettingsPage())),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 32)),
              Consumer(
                  builder: (context, ref, _) => ListTile(
                      leading:
                          const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text('Logout',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold)),
                      onTap: () async {
                        Navigator.pop(context);
                        await ref.read(authProvider.notifier).signOut();
                      })),
            ],
          ),
        ),
      ),
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            border: Border(
                top: BorderSide(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    width: 1))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navIcon(0, Icons.home_rounded,
                    Theme.of(context).colorScheme.primary),
                _navIcon(1, Icons.track_changes,
                    Theme.of(context).colorScheme.primary),
                _navIcon(
                    2, Icons.flash_on, Theme.of(context).colorScheme.secondary),
                _navIcon(3, Icons.receipt_long,
                    Theme.of(context).colorScheme.primary),
                _navIcon(4, Icons.emoji_events,
                    Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AiAssistantPage())),
        backgroundColor: const Color(0xFF6A5AE0),
        child:
            const Icon(Icons.auto_awesome, color: Color(0xFFC0FF00), size: 30),
      ),
    );
  }

  Widget _topStat(
      {required IconData icon, required String value, required Color color}) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(value,
              style: TextStyle(
                  color: color == const Color(0xFFC0FF00)
                      ? const Color(0xFF1A1A1A)
                      : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14))
        ]));
  }

  Widget _navIcon(int index, IconData icon, Color color) {
    final isSelected = _index == index;
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: isSelected
                  ? (color == const Color(0xFFC0FF00)
                      ? color
                      : color.withValues(alpha: 0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16)),
          child: Icon(icon,
              size: 26,
              color: isSelected
                  ? (color == const Color(0xFFC0FF00)
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : const Color(0xFF1A1A1A))
                      : color)
                  : const Color(0xFF94A3B8))),
    );
  }

  void _openThenClose(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _drawerTile(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
        leading: Icon(icon,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        title: Text(label),
        onTap: onTap);
  }
}

class _HomeTabBody extends ConsumerWidget {
  const _HomeTabBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(scenarioPacksProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6A5AE0), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF6A5AE0).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('UNIT 1',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2))),
                const SizedBox(height: 16),
                Text('Master the basics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                        value: 0.4,
                        backgroundColor: Colors.white24,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFC0FF00)),
                        minHeight: 8)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: packs.length,
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemBuilder: (context, index) {
              final pack = packs[index];
              final isActive = pack.modules.any((m) => !m.completed);
              final isCompleted = pack.modules.every((m) => m.completed);
              final offset = (index % 4 == 0)
                  ? 0.0
                  : (index % 4 == 1 || index % 4 == 3)
                      ? 50.0
                      : 100.0;

              return Padding(
                padding: EdgeInsets.only(
                    left: offset, right: 100 - offset, bottom: 40),
                child: _JourneyNode(
                  title: pack.title,
                  isActive: isActive,
                  isCompleted: isCompleted,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ScenariosPage())),
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: const Color(0xFFC0FF00).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: const Color(0xFFC0FF00).withValues(alpha: 0.3))),
            child: const Row(children: [
              Icon(Icons.bolt_rounded, color: Color(0xFF1A1A1A), size: 32),
              SizedBox(width: 16),
              Expanded(
                  child: Text("Keep it up! You're doing great.",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A))))
            ]),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _JourneyNode extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  const _JourneyNode(
      {required this.title,
      required this.isActive,
      required this.isCompleted,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    Color contentColor = const Color(0xFF94A3B8);
    IconData icon = Icons.lock_outline_rounded;

    if (isCompleted) {
      color = const Color(0xFF6A5AE0);
      contentColor = Colors.white;
      icon = Icons.check_rounded;
    } else if (isActive) {
      color = const Color(0xFFC0FF00);
      contentColor = isDark ? Colors.black : const Color(0xFF1A1A1A);
      icon = Icons.play_arrow_rounded;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InteractiveButton(
          onTap: onTap,
          isPrimary: isActive,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
                child: Icon(icon,
                    color: isCompleted || isActive
                        ? contentColor
                        : const Color(0xFF94A3B8),
                    size: 40)),
          ),
        ),
        const SizedBox(height: 12),
        Text(title.toUpperCase(),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 1.1)),
      ],
    );
  }
}
