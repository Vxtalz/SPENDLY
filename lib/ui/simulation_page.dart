import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/simulation_provider.dart';

class SimulationPage extends ConsumerStatefulWidget {
  const SimulationPage({super.key});

  @override
  ConsumerState<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends ConsumerState<SimulationPage> {
  final _amountController = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _logExpense() async {
    final value = double.tryParse(_amountController.text);
    if (value == null || value <= 0) return;

    await ref.read(simulationProvider.notifier).logExpense(value);

    final client = Supabase.instance.client;
    final userId = _userId;
    if (userId != null) {
      try {
        await client.from('transactions').insert({
          'user_id': userId,
          'amount': -value,
          'category': 'daily_spend',
          'type': 'expense',
          'description': 'Daily expense',
        });
      } catch (_) {
        // Log locally or show offline snackbar if needed
      }
    }

    _amountController.clear();
  }

  Future<void> _logSaving() async {
    final value = double.tryParse(_amountController.text);
    if (value == null || value <= 0) return;

    await ref.read(simulationProvider.notifier).logSaving(value);

    final client = Supabase.instance.client;
    final userId = _userId;
    if (userId != null) {
      try {
        await client.from('transactions').insert({
          'user_id': userId,
          'amount': value,
          'category': 'savings',
          'type': 'saving',
          'description': 'Saved from allowance',
        });
      } catch (_) {
        // Log locally or show offline snackbar if needed
      }
    }

    _amountController.clear();
  }

  Future<Map<String, dynamic>> _computeWeeklySummary() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return {'spent': 0, 'saved': 0};

    final fromDate = DateTime.now().subtract(const Duration(days: 7));

    try {
      final data = await client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .gte('created_at', fromDate.toIso8601String());

      double spent = 0;
      double saved = 0;

      for (final tx in data) {
        final amount = (tx['amount'] as num).toDouble();
        final type = tx['type'] as String;
        if (type == 'expense') spent += -amount;
        if (type == 'saving') saved += amount;
      }

      return {'spent': spent, 'saved': saved};
    } catch (_) {
      return {'spent': 0, 'saved': 0};
    }
  }

  Future<Map<String, dynamic>> _computeCycleSummary() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return {'spent': 0, 'saved': 0, 'debt': 0};

    final fromDate = DateTime.now().subtract(const Duration(days: 30));
    try {
      final txs = await client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .gte('created_at', fromDate.toIso8601String());

      double spent = 0;
      double saved = 0;

      for (final tx in txs) {
        final amount = (tx['amount'] as num).toDouble();
        final type = tx['type'] as String;
        if (type == 'expense') spent += -amount;
        if (type == 'saving') saved += amount;
      }

      final state = ref.read(simulationProvider);
      return {
        'spent': spent,
        'saved': saved,
        'debt': state.debt,
      };
    } catch (_) {
      return {'spent': 0, 'saved': 0, 'debt': 0};
    }
  }

  Future<void> _awardBadge(String key, String label) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final existing = await client
          .from('badges')
          .select()
          .eq('user_id', userId)
          .eq('badge_key', key)
          .maybeSingle();

      if (existing != null) return;

      await client.from('badges').insert({
        'user_id': userId,
        'badge_key': key,
        'label': label,
      });
    } catch (_) {}
  }

  Future<void> _showWeeklyReport() async {
    final summary = await _computeWeeklySummary();
    final spent = summary['spent'] as double;
    final saved = summary['saved'] as double;
    String message;
    String? badgeKey;
    String? badgeLabel;

    if (spent <= 0 && saved <= 0) {
      message =
          'Walang galaw pa this week. Try logging your real choices tomorrow.';
    } else if (saved >= spent * 0.3) {
      message = 'Astig! You saved at least 30% of what you spent this week.';
      badgeKey = 'weekly_saver';
      badgeLabel = 'Weekly Saver';
    } else if (spent > saved * 3) {
      message =
          'Medyo magastos this week. Next time, try to park more in savings.';
      badgeKey = 'weekly_spender';
      badgeLabel = 'Big Spender (Lesson Learned)';
    } else {
      message = 'Decent balance this week. Keep practicing good habits.';
    }

    if (badgeKey != null && badgeLabel != null) {
      await _awardBadge(badgeKey, badgeLabel);
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Weekly report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You spent: ₱${spent.toStringAsFixed(0)}'),
              Text('You saved: ₱${saved.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              Text(message),
              if (badgeLabel != null) ...[
                const SizedBox(height: 12),
                Text('Badge earned: $badgeLabel'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Okay'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCycleReport() async {
    final summary = await _computeCycleSummary();
    if (!mounted) return;

    final spent = summary['spent'] as double;
    final saved = summary['saved'] as double;
    final debtAtEnd = summary['debt'] as double;

    String verdict;
    if (debtAtEnd > 0 && saved == 0) {
      verdict =
          'Cycle finished with utang and no savings. Next cycle, prioritize paying debt first.';
    } else if (saved >= spent * 0.25 && debtAtEnd <= 0) {
      verdict = 'Solid cycle! You saved a good chunk and avoided debt.';
    } else {
      verdict = 'Mixed cycle. Check your history and see where you can adjust.';
    }

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('30-day cycle summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total spent: ₱${spent.toStringAsFixed(0)}'),
              Text('Total saved: ₱${saved.toStringAsFixed(0)}'),
              Text('Debt at end: ₱${debtAtEnd.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              Text(verdict),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Next cycle'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _nextDay() async {
    final oldState = ref.read(simulationProvider);
    await ref.read(simulationProvider.notifier).nextDay();
    final newState = ref.read(simulationProvider);

    if (newState.currentDay == 1 &&
        newState.cycleNumber > oldState.cycleNumber) {
      await _showCycleReport();
    } else if (newState.currentDay % 7 == 1 && newState.currentDay != 1) {
      await _showWeeklyReport();
    }

    if (newState.streakDays == 30) {
      await _awardBadge('perfect_streak', 'Perfect Streak');
    }
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(simulationProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header: Today's simulation day
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A5AE0), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A5AE0).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'DAILY SIMULATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Day ${simState.currentDay} of 30',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: simState.currentDay / 30,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC0FF00), // Electric Lime
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Mascot bubble
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology,
                  color: Color(0xFF6A5AE0), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "Time for your daily choices! Every decision shapes your financial future.",
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Daily Choice Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    size: 40, color: Color(0xFF6A5AE0)),
              ),
              const SizedBox(height: 16),
              Text(
                'Daily Coffee Run',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Treat yourself to a specialty latte or skip it today?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 28),
              _ChoiceTile(
                icon: Icons.coffee_rounded,
                label: 'Buy Coffee',
                hint: 'A quick treat',
                cost: '- ₱180',
                color: const Color(0xFF6A5AE0),
                onTap: _logExpense,
              ),
              const SizedBox(height: 12),
              _ChoiceTile(
                icon: Icons.savings_rounded,
                label: 'Save Money',
                hint: 'For the future',
                cost: '+ ₱180',
                color: const Color(0xFFC0FF00),
                onTap: _logSaving,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _nextDay,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFC0FF00)
                  : const Color(0xFF1A1A1A),
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt_rounded,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : const Color(0xFFC0FF00)),
                const SizedBox(width: 12),
                const Text(
                  'NEXT DAY',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Mini stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _MiniStat(
                label: 'Wallet',
                value: _currency.format(simState.balance),
                color: Theme.of(context).colorScheme.onSurface),
            _MiniStat(
                label: 'Savings',
                value: _currency.format(simState.savings),
                color: const Color(0xFF6A5AE0)),
            _MiniStat(
                label: 'Streak',
                value: '${simState.streakDays} Days',
                color: Theme.of(context).colorScheme.onSurface),
          ],
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final String hint;
  final String cost;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.hint,
    required this.cost,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              cost,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
