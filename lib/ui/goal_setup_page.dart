import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers/goal_provider.dart';

class GoalSetupPage extends ConsumerStatefulWidget {
  const GoalSetupPage({super.key});

  @override
  ConsumerState<GoalSetupPage> createState() => _GoalSetupPageState();
}

class _GoalSetupPageState extends ConsumerState<GoalSetupPage> {
  GoalPeriod _period = GoalPeriod.daily;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Goal to Spend')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose period'),
            const SizedBox(height: 8),
            DropdownButtonFormField<GoalPeriod>(
              initialValue: _period,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: GoalPeriod.daily, child: Text('Daily')),
                DropdownMenuItem(value: GoalPeriod.weekly, child: Text('Weekly')),
              ],
              onChanged: (v) => setState(() => _period = v ?? GoalPeriod.daily),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₱)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final pesos = int.tryParse(_controller.text.trim());
                  if (pesos == null || pesos <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')),
                    );
                    return;
                  }
                  ref.read(goalProvider.notifier).setGoal(_period, pesos * 100);
                  Navigator.pop(context);
                },
                child: const Text('Save Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
