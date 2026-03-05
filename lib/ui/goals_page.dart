import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _goals = [];

  static const _primaryGreen = Color(0xFF22C55E);
  static const _darkNavy = Color(0xFF0F172A);

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
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target amount (₱)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF22C55E)),
      );
    }

    double weeklySaved = 0;
    double weeklyTarget = 0;
    for (final g in _goals) {
      weeklyTarget += (g['target_amount'] as num).toDouble();
      weeklySaved += (g['current_amount'] as num?)?.toDouble() ?? 0;
    }
    if (weeklyTarget == 0) weeklyTarget = 1;
    final weeklyProgress = (weeklySaved / weeklyTarget).clamp(0.0, 1.0);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Yellow gradient hero: weekly savings progress
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFDE047),
                      Color(0xFFFACC15),
                      Color(0xFFEAB308),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly savings',
                      style: TextStyle(
                        color: _darkNavy.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${weeklySaved.toStringAsFixed(0)} of ₱${weeklyTarget.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: _darkNavy,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: weeklyProgress,
                        minHeight: 10,
                        backgroundColor: Colors.white54,
                        valueColor: const AlwaysStoppedAnimation<Color>(_darkNavy),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_goals.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No goals yet. Tap the button below to add one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(_goals.length, (index) {
                  final goal = _goals[index];
                  final name = goal['name'] as String;
                  final target = (goal['target_amount'] as num).toDouble();
                  final current = (goal['current_amount'] as num?)?.toDouble() ?? 0;
                  final progress = (target == 0) ? 0.0 : (current / target).clamp(0.0, 1.0);
                  final remaining = (target - current).clamp(0.0, double.infinity);
                  final percent = (progress * 100).round();
                  final colors = [
                    _primaryGreen,
                    const Color(0xFF3B82F6),
                    const Color(0xFF8B5CF6),
                    const Color(0xFFEC4899),
                  ];
                  final color = colors[index % colors.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _darkNavy,
                              ),
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: color.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₱${current.toStringAsFixed(0)} / ₱${target.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '$percent% · ₱${remaining.toStringAsFixed(0)} left',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createGoal,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add a new goal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
