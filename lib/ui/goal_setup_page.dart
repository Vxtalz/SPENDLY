import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers/goal_provider.dart';
import 'widgets/interactive_widgets.dart';

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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose period',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<GoalPeriod>(
              value: _period,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
              ),
              items: const [
                DropdownMenuItem(value: GoalPeriod.daily, child: Text('Daily')),
                DropdownMenuItem(
                    value: GoalPeriod.weekly, child: Text('Weekly')),
              ],
              onChanged: (v) => setState(() => _period = v ?? GoalPeriod.daily),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₱)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: InteractiveButton(
                isPrimary: true,
                onTap: () {
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
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0FF00),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Save Goal',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
