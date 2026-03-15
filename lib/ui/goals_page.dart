import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/simulation_provider.dart';
import '../providers/transaction_provider.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;
    final data = await client
        .from('goals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    if (mounted) {
      setState(() {
        _goals = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    }
  }

  Future<void> _createGoal() async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        final navigator = Navigator.of(context);
        return AlertDialog(
          title: const Text('New goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target amount (₱)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final target =
                    double.tryParse(targetController.text.trim()) ?? 0;
                if (name.isEmpty || target <= 0) return;

                final client = Supabase.instance.client;
                final userId = client.auth.currentUser!.id;

                await client.from('goals').insert({
                  'user_id': userId,
                  'name': name,
                  'target_amount': target,
                });

                navigator.pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    await _loadGoals();
  }

  Future<void> _deleteGoal(String goalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: const Text(
            'Are you sure you want to remove this goal? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final client = Supabase.instance.client;
      await client.from('goals').delete().eq('id', goalId);
      await _loadGoals();
    }
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(simulationProvider);
    final txs = ref.watch(transactionListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF58CC02)),
      );
    }

    double totalSaved = simState.savings;
    double totalTarget = 0;
    for (final g in _goals) {
      totalTarget += (g['target_amount'] as num).toDouble();
    }
    if (totalTarget == 0) totalTarget = 1;
    final totalProgress = (totalSaved / totalTarget).clamp(0.0, 1.0);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Hero Section
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'SAVINGS PROGRESS',
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
                      '₱${totalSaved.toStringAsFixed(0)} / ₱${totalTarget.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          widthFactor: totalProgress,
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
              if (_goals.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No goals yet. Start small and watch your savings grow!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFAFAFAF),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(_goals.length, (index) {
                  final goal = _goals[index];
                  final id = goal['id'].toString();
                  final name = goal['name'] as String;
                  final target = (goal['target_amount'] as num).toDouble();
                  
                  final currentCents = txs
                      .where((t) => t.type == 'save' && t.category.trim() == name.trim())
                      .fold(0, (sum, t) => sum + t.amountCents);
                  final current = currentCents / 100.0;
                  
                  final progress =
                      (target == 0) ? 0.0 : (current / target).clamp(0.0, 1.0);
                  final percent = (progress * 100).round();

                  final List<Color> colors = [
                    const Color(0xFF6A5AE0),
                    const Color(0xFFC0FF00),
                    const Color(0xFF00D1FF),
                    const Color(0xFFFF4B4B),
                  ];
                  final color = colors[index % colors.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.star_rounded, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.grey),
                                onPressed: () => _deleteGoal(id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₱${current.toStringAsFixed(0)} / ₱${target.toStringAsFixed(0)} saved',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '$percent% done',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: (color == const Color(0xFFC0FF00) &&
                                          isDark)
                                      ? Colors.black
                                      : color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        // Add Goal Button
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _createGoal,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? const Color(0xFFC0FF00) : const Color(0xFF1A1A1A),
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded,
                      color: isDark ? Colors.black : const Color(0xFFC0FF00)),
                  const SizedBox(width: 12),
                  const Text(
                    'ADD A NEW GOAL',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
