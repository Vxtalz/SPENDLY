import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/transaction_provider.dart';
import '../providers/goal_provider.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'Food');
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(transactionListProvider);
    final goal = ref.watch(goalProvider);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final dayTotal = ref.read(transactionListProvider.notifier).totalBetween(startOfDay, endOfDay);

    return Scaffold(
      appBar: AppBar(title: const Text('Real Transactions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today: ₱${(dayTotal / 100).toStringAsFixed(2)}'),
                if (goal != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: goal.progress),
                  const SizedBox(height: 4),
                  Text('Goal: ₱${(goal.amountCents / 100).toStringAsFixed(0)} • Spent: ₱${(goal.spentCents / 100).toStringAsFixed(0)}'),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: txs.length,
              itemBuilder: (context, i) {
                final t = txs[i];
                return ListTile(
                  title: Text('${t.category} • ₱${(t.amountCents / 100).toStringAsFixed(2)}'),
                  subtitle: Text(t.note ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(transactionListProvider.notifier).remove(t.id),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount (₱)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _categoryCtrl,
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final pesos = int.tryParse(_amountCtrl.text.trim());
                      if (pesos == null || pesos <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
                        return;
                      }
                      await ref.read(transactionListProvider.notifier).add(
                            amountCents: pesos * 100,
                            category: _categoryCtrl.text.trim().isEmpty ? 'Other' : _categoryCtrl.text.trim(),
                            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                          );
                      // update goal progress
                      await ref.read(goalProvider.notifier).addSpending(pesos * 100);
                      _amountCtrl.clear();
                      _noteCtrl.clear();
                    },
                    child: const Text('Add Transaction'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
