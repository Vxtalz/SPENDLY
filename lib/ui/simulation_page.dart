import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/simulation_provider.dart';
import 'widgets/interactive_widgets.dart';

class SimulationPage extends ConsumerStatefulWidget {
  const SimulationPage({super.key});

  @override
  ConsumerState<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends ConsumerState<SimulationPage> {
  final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  String? _selectedChoiceId;
  String? _consequenceText;
  bool _isSuccess = false;

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> _handleChoice(
      String id, String label, double amount, bool isSaving) async {
    if (_selectedChoiceId != null) return;

    setState(() {
      _selectedChoiceId = id;
      _isSuccess = isSaving;
      _consequenceText = isSaving
          ? "Great choice! Saving $label builds your future security."
          : "You spent $label. It's a treat, but remember your long-term goals!";
    });

    final notifier = ref.read(simulationProvider.notifier);
    if (isSaving) {
      await notifier.logSaving(amount);
    } else {
      await notifier.logExpense(amount);
    }

    final client = Supabase.instance.client;
    final userId = _userId;
    if (userId != null) {
      try {
        await client.from('transactions').insert({
          'user_id': userId,
          'amount': isSaving ? amount : -amount,
          'category': isSaving ? 'savings' : 'daily_spend',
          'type': isSaving ? 'saving' : 'expense',
          'description': isSaving ? 'Saved from $label' : 'Spent on $label',
        });
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> _computeWeeklySummary() async {
    final client = Supabase.instance.client;
    if (_userId == null) return {'spent': 0.0, 'saved': 0.0};
    final fromDate = DateTime.now().subtract(const Duration(days: 7));
    try {
      final data = await client
          .from('transactions')
          .select()
          .eq('user_id', _userId!)
          .gte('created_at', fromDate.toIso8601String());
      double spent = 0;
      double saved = 0;
      for (final tx in data) {
        final amount = (tx['amount'] as num).toDouble();
        if (tx['type'] == 'expense') spent += -amount;
        if (tx['type'] == 'saving') saved += amount;
      }
      return {'spent': spent, 'saved': saved};
    } catch (_) {
      return {'spent': 0.0, 'saved': 0.0};
    }
  }

  Future<Map<String, dynamic>> _computeCycleSummary() async {
    final client = Supabase.instance.client;
    if (_userId == null) return {'spent': 0.0, 'saved': 0.0, 'debt': 0.0};
    final fromDate = DateTime.now().subtract(const Duration(days: 30));
    try {
      final txs = await client
          .from('transactions')
          .select()
          .eq('user_id', _userId!)
          .gte('created_at', fromDate.toIso8601String());
      double spent = 0;
      double saved = 0;
      for (final tx in txs) {
        final amount = (tx['amount'] as num).toDouble();
        if (tx['type'] == 'expense') spent += -amount;
        if (tx['type'] == 'saving') saved += amount;
      }
      return {
        'spent': spent,
        'saved': saved,
        'debt': ref.read(simulationProvider).debt
      };
    } catch (_) {
      return {'spent': 0.0, 'saved': 0.0, 'debt': 0.0};
    }
  }

  Future<void> _awardBadge(String key, String label) async {
    if (_userId == null) return;
    try {
      final client = Supabase.instance.client;
      final existing = await client
          .from('badges')
          .select()
          .eq('user_id', _userId!)
          .eq('badge_key', key)
          .maybeSingle();
      if (existing == null)
        await client
            .from('badges')
            .insert({'user_id': _userId!, 'badge_key': key, 'label': label});
    } catch (_) {}
  }

  Future<void> _showWeeklyReport() async {
    final summary = await _computeWeeklySummary();
    final spent = summary['spent'] as double;
    final saved = summary['saved'] as double;
    String message = spent > saved * 3
        ? 'Medyo magastos this week.'
        : 'Decent balance this week.';
    if (saved >= spent * 0.3) {
      message = 'Astig! You saved at least 30%.';
      await _awardBadge('weekly_saver', 'Weekly Saver');
    }
    if (!mounted) return;
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Weekly report'),
              content: Text(
                  'Spent: ₱${spent.toStringAsFixed(0)}\nSaved: ₱${saved.toStringAsFixed(0)}\n\n$message'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Okay'))
              ],
            ));
  }

  Future<void> _showCycleReport() async {
    final summary = await _computeCycleSummary();
    if (!mounted) return;
    final spent = summary['spent'] as double;
    final saved = summary['saved'] as double;
    final debt = summary['debt'] as double;
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('30-day summary'),
              content: Text(
                  'Spent: ₱${spent.toStringAsFixed(0)}\nSaved: ₱${saved.toStringAsFixed(0)}\nDebt: ₱${debt.toStringAsFixed(0)}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Next cycle'))
              ],
            ));
  }

  Future<void> _nextDay() async {
    final oldState = ref.read(simulationProvider);
    await ref.read(simulationProvider.notifier).nextDay();
    final newState = ref.read(simulationProvider);

    setState(() {
      _selectedChoiceId = null;
      _consequenceText = null;
    });

    if (newState.currentDay == 1 &&
        newState.cycleNumber > oldState.cycleNumber) {
      await _showCycleReport();
    } else if (newState.currentDay % 7 == 1 && newState.currentDay != 1) {
      await _showWeeklyReport();
    }
    if (newState.streakDays == 30)
      await _awardBadge('perfect_streak', 'Perfect Streak');
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(simulationProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
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
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text('Your lifetime daily money companion',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1))),
              const SizedBox(height: 16),
              Text('Day ${simState.currentDay} of 30',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Stack(children: [
                Container(
                    height: 10,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(5))),
                FractionallySizedBox(
                    widthFactor: simState.currentDay / 30,
                    child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                            color: const Color(0xFFC0FF00),
                            borderRadius: BorderRadius.circular(5)))),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 32),
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
                    offset: const Offset(0, 10))
              ]),
          child: Column(
            children: [
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.shopping_bag_outlined,
                      size: 40, color: Color(0xFF6A5AE0))),
              const SizedBox(height: 16),
              const Text('Daily Coffee Run',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Treat yourself or skip today?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
              const SizedBox(height: 28),
              _ChoiceTile(
                  id: 'buy_coffee',
                  icon: Icons.coffee_rounded,
                  label: 'Buy Coffee',
                  hint: 'A quick treat',
                  cost: '- ₱180',
                  color: const Color(0xFF6A5AE0),
                  isSelected: _selectedChoiceId == 'buy_coffee',
                  isSuccess: false,
                  onTap: () =>
                      _handleChoice('buy_coffee', 'Coffee', 180, false)),
              const SizedBox(height: 12),
              _ChoiceTile(
                  id: 'save_coffee',
                  icon: Icons.savings_rounded,
                  label: 'Save Money',
                  hint: 'For the future',
                  cost: '+ ₱180',
                  color: const Color(0xFFC0FF00),
                  isSelected: _selectedChoiceId == 'save_coffee',
                  isSuccess: true,
                  onTap: () => _handleChoice(
                      'save_coffee', 'Coffee savings', 180, true)),
              const SizedBox(height: 24),
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                child: _consequenceText == null
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: _isSuccess
                                ? const Color(0xFFC0FF00).withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _isSuccess
                                    ? const Color(0xFFC0FF00)
                                        .withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3))),
                        child: Row(children: [
                          Icon(
                              _isSuccess
                                  ? Icons.check_circle
                                  : Icons.info_outline,
                              color: _isSuccess
                                  ? const Color(0xFF1B5E20)
                                  : Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(_consequenceText!,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _isSuccess
                                          ? const Color(0xFF1B5E20)
                                          : Colors.red))),
                        ]),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: InteractiveButton(
              isPrimary: true,
              onTap: _nextDay,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20)),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFFC0FF00)),
                  const SizedBox(width: 12),
                  const Text('NEXT DAY',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1)),
                ]),
              )),
        ),
        const SizedBox(height: 32),
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
  final String id, label, hint, cost;
  final IconData icon;
  final Color color;
  final bool isSelected, isSuccess;
  final VoidCallback onTap;

  const _ChoiceTile(
      {required this.id,
      required this.label,
      required this.hint,
      required this.cost,
      required this.icon,
      required this.color,
      required this.isSelected,
      required this.isSuccess,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InteractiveButton(
      onTap: onTap,
      isSuccess: isSelected && isSuccess,
      isError: isSelected && !isSuccess,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected
                    ? color
                    : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                width: 2)),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                Text(hint,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF94A3B8))),
              ])),
          Text(cost,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              letterSpacing: 1.1)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}
