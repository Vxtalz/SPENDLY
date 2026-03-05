import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SimulationPage extends StatefulWidget {
  const SimulationPage({super.key});

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  bool _loading = true;
  double _balance = 0;
  double _savings = 0;
  double _debt = 0;
  int _currentDay = 1;
  int _cycleNumber = 1;
  int _streakDays = 0;
  DateTime? _lastPlayedDate;

  final _amountController = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;

    final response = await client
        .from('simulation_state')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      await client.from('simulation_state').insert({
        'user_id': userId,
        'current_day': 1,
        'cycle_number': 1,
        'balance': 300.0,
        'savings': 0.0,
        'debt': 0.0,
        'streak_days': 0,
      });
      _balance = 300.0;
      _savings = 0.0;
      _debt = 0.0;
      _currentDay = 1;
      _cycleNumber = 1;
      _streakDays = 0;
    } else {
      _balance = (response['balance'] as num).toDouble();
      _savings = (response['savings'] as num).toDouble();
      _debt = (response['debt'] as num).toDouble();
      _currentDay = (response['current_day'] as int? ?? 1);
      _cycleNumber = (response['cycle_number'] as int? ?? 1);
      _streakDays = (response['streak_days'] as int? ?? 0);
      final lastPlayedStr = response['last_played_date'] as String?;
      _lastPlayedDate =
          lastPlayedStr != null ? DateTime.parse(lastPlayedStr) : null;
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _commitState() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    await client.from('simulation_state').upsert({
      'user_id': userId,
      'current_day': _currentDay,
      'cycle_number': _cycleNumber,
      'balance': _balance,
      'savings': _savings,
      'debt': _debt,
      'streak_days': _streakDays,
      'last_played_date': todayDate.toIso8601String().substring(0, 10),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _logExpense() async {
    final value = double.tryParse(_amountController.text);
    if (value == null || value <= 0) return;

    setState(() {
      _balance -= value;
    });

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;

    await client.from('transactions').insert({
      'user_id': userId,
      'amount': -value,
      'category': 'daily_spend',
      'type': 'expense',
      'description': 'Daily expense',
    });

    await _commitState();
    _amountController.clear();
  }

  Future<void> _logSaving() async {
    final value = double.tryParse(_amountController.text);
    if (value == null || value <= 0) return;

    setState(() {
      _balance -= value;
      _savings += value;
    });

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;

    await client.from('transactions').insert({
      'user_id': userId,
      'amount': value,
      'category': 'savings',
      'type': 'saving',
      'description': 'Saved from allowance',
    });

    await _commitState();
    _amountController.clear();
  }

  Future<Map<String, dynamic>> _computeWeeklySummary() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;

    final fromDate = DateTime.now().subtract(const Duration(days: 7));

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

    return {
      'spent': spent,
      'saved': saved,
    };
  }

  Future<Map<String, dynamic>> _computeCycleSummary() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;

    final fromDate = DateTime.now().subtract(const Duration(days: 30));
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

    final state = await client
        .from('simulation_state')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    final debt = state != null ? (state['debt'] as num).toDouble() : 0;

    return {
      'spent': spent,
      'saved': saved,
      'debt': debt,
    };
  }

  Future<void> _awardBadge(String key, String label) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;

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

    final navigator = Navigator.of(context);

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
              onPressed: () => navigator.pop(),
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
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (_lastPlayedDate == null) {
      _streakDays = 1;
    } else {
      final diff = todayDate.difference(_lastPlayedDate!).inDays;
      if (diff == 1) {
        _streakDays += 1;
      } else if (diff > 1) {
        _streakDays = 1;
      }
    }
    _lastPlayedDate = todayDate;

    if (_streakDays == 30) {
      await _awardBadge('perfect_streak', 'Perfect Streak');
    }

    setState(() {
      _currentDay += 1;

      final finishedCycle = _currentDay > 30;
      if (finishedCycle) {
        _cycleNumber += 1;
        _currentDay = 1;
      }

      double dailyAllowance = 300;
      if (_streakDays >= 10) {
        dailyAllowance *= 1.2;
      } else if (_streakDays >= 5) {
        dailyAllowance *= 1.1;
      }

      _balance += dailyAllowance.roundToDouble();

      if (finishedCycle && _debt > 0) {
        _balance -= (_debt * 0.1);
      }
    });

    await _commitState();

    if (_currentDay == 1) {
      await _showCycleReport();
    } else if (_currentDay == 8 ||
        _currentDay == 15 ||
        _currentDay == 22 ||
        _currentDay == 29) {
      await _showWeeklyReport();
    }
  }

  static const _primaryGreen = Color(0xFF22C55E);
  static const _darkNavy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)));
    }

    final daysLeft = 30 - _currentDay + 1;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Active scenario card: countdown, emoji, question, choices
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day $_currentDay of 30',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$daysLeft days left',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('💰', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  'Morning',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'What will you do with today\'s money?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter an amount below, then choose to spend it or save it. Each day you get a fresh allowance.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (₱)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                // Two choice cards: red spend, green save
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _amountController,
                  builder: (_, value, __) {
                    final costStr = value.text.trim().isEmpty
                        ? '—'
                        : _currency.format(double.tryParse(value.text) ?? 0);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DailyChoiceCard(
                          label: 'Spend',
                          hint: 'Use it for food, transport, or wants',
                          cost: costStr,
                          isSpend: true,
                          onTap: _logExpense,
                        ),
                        const SizedBox(height: 10),
                        _DailyChoiceCard(
                          label: 'Save',
                          hint: 'Move it to savings for your goals',
                          cost: costStr,
                          isSpend: false,
                          onTap: _logSaving,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _nextDay,
                    icon: const Icon(Icons.flash_on, size: 20),
                    label: const Text('Next day'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _darkNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Wallet: ${_currency.format(_balance)} · Savings: ${_currency.format(_savings)} · Streak: $_streakDays days',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DailyChoiceCard extends StatelessWidget {
  final String label;
  final String hint;
  final String cost;
  final bool isSpend;
  final VoidCallback onTap;

  const _DailyChoiceCard({
    required this.label,
    required this.hint,
    required this.cost,
    required this.isSpend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSpend ? const Color(0xFFDC2626) : const Color(0xFF22C55E);
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(isSpend ? Icons.shopping_bag_outlined : Icons.savings_outlined,
                  color: color, size: 28),
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
                        color: color,
                      ),
                    ),
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                cost,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

