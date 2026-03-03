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
                decoration: const InputDecoration(labelText: 'Goal name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Target amount (₱)'),
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
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _goals.isEmpty
          ? const Center(
              child: Text('No goals yet. Create one to start saving!'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, index) {
                final goal = _goals[index];
                final name = goal['name'] as String;
                final target = (goal['target_amount'] as num).toDouble();
                final current = (goal['current_amount'] as num).toDouble();
                final progress = (target == 0) ? 0.0 : (current / target);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.track_changes),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${current.toStringAsFixed(0)} / ₱${target.toStringAsFixed(0)}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _goals.length,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createGoal,
        child: const Icon(Icons.add_circle_outline),
      ),
    );
  }
}

