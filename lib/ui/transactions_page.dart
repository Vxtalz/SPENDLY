import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/interactive_widgets.dart';

import '../models.dart';
import '../providers/transaction_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/simulation_provider.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'Food');
  final _noteCtrl = TextEditingController();
  bool _isExpense = true;

  static const _primaryGreen = Color(0xFF22C55E);

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
    final dayTotal = ref
        .read(transactionListProvider.notifier)
        .totalBetween(startOfDay, endOfDay);

    int totalIncome = 0;
    int totalExpense = 0;
    for (final t in txs) {
      if (!t.timestamp.isBefore(startOfDay) && t.timestamp.isBefore(endOfDay)) {
        if (t.amountCents > 0) {
          totalIncome += t.amountCents;
        } else {
          totalExpense += -t.amountCents;
        }
      }
    }
    final displayIncome = totalIncome;

    final byDate = <DateTime, List<TransactionEntry>>{};
    for (final t in txs) {
      final d = DateTime(t.timestamp.year, t.timestamp.month, t.timestamp.day);
      byDate.putIfAbsent(d, () => []).add(t);
    }
    for (final list in byDate.values) {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).cardColor;
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.1);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: dividerColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.arrow_downward_rounded,
                                    color: _primaryGreen, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'Incoming',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: onSurface.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₱${(displayIncome / 100).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: dividerColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.arrow_upward_rounded,
                                    color: Colors.red.shade400, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'Expenses',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: onSurface.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₱${(totalExpense / 100).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (goal != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Today: ₱${(dayTotal / 100).toStringAsFixed(0)} · Goal ₱${(goal.amountCents / 100).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: goal.progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: dividerColor,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_primaryGreen),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFC0FF00),
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  totalExpense > displayIncome
                      ? "Keep it up! Your spending is a bit high today, but we can fix it!"
                      : "Looking good! You're making smart money moves today.",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: dividerColor),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _buildDateSection(
                context,
                startOfDay,
                (byDate[startOfDay] ?? [])
                    .map(
                      (t) => _TransactionItem(
                        id: t.id,
                        category: t.category,
                        note: t.note,
                        amountCents: t.amountCents,
                        timestamp: t.timestamp,
                        isSample: false,
                      ),
                    )
                    .toList(),
              ),
              ...sortedDates.where((d) => d != startOfDay).map(
                    (d) => _buildDateSection(
                      context,
                      d,
                      (byDate[d] ?? [])
                          .map(
                            (t) => _TransactionItem(
                              id: t.id,
                              category: t.category,
                              note: t.note,
                              amountCents: t.amountCents,
                              timestamp: t.timestamp,
                              isSample: false,
                            ),
                          )
                          .toList(),
                    ),
                  ),
            ],
          ),
        ),
        Divider(height: 1, color: dividerColor),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                ],
                selected: {_isExpense},
                onSelectionChanged: (val) {
                  setState(() {
                    _isExpense = val.first;
                    if (_isExpense && _categoryCtrl.text == 'Income') {
                      _categoryCtrl.text = 'Food';
                    } else if (!_isExpense && _categoryCtrl.text == 'Food') {
                      _categoryCtrl.text = 'Income';
                    }
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: _isExpense
                      ? Colors.red.withValues(alpha: 0.1)
                      : _primaryGreen.withValues(alpha: 0.1),
                  selectedForegroundColor:
                      _isExpense ? Colors.red : _primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₱)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
              ),
              const SizedBox(height: 16),
              InteractiveButton(
                onTap: () async {
                  final pesos = int.tryParse(_amountCtrl.text.trim());
                  if (pesos == null || pesos <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter valid amount')),
                    );
                    return;
                  }

                  final amountCents =
                      _isExpense ? -(pesos * 100) : (pesos * 100);

                  final simNotifier = ref.read(simulationProvider.notifier);
                  final txNotifier = ref.read(transactionListProvider.notifier);

                  if (_isExpense) {
                    await simNotifier.logExpense(pesos.toDouble());
                  } else {
                    final curr = ref.read(simulationProvider);
                    await simNotifier.updateState(curr.copyWith(
                      balance: curr.balance + pesos,
                    ));
                  }

                  await txNotifier.add(
                    amountCents: amountCents,
                    category: _categoryCtrl.text.trim().isEmpty
                        ? 'Other'
                        : _categoryCtrl.text.trim(),
                    note: _noteCtrl.text.trim().isEmpty
                        ? null
                        : _noteCtrl.text.trim(),
                  );

                  // If it's income, let's treat it as progress towards our goal
                  if (!_isExpense) {
                    final client = Supabase.instance.client;
                    final user = client.auth.currentUser;
                    if (user != null) {
                      try {
                        // Find the first active goal and add to it
                        final goals = await client
                            .from('goals')
                            .select()
                            .eq('user_id', user.id)
                            .order('created_at', ascending: true)
                            .limit(1);

                        if (goals.isNotEmpty) {
                          final goalId = goals[0]['id'];
                          final currentAmount =
                              (goals[0]['current_amount'] as num?)
                                      ?.toDouble() ??
                                  0;
                          await client.from('goals').update({
                            'current_amount': currentAmount + pesos,
                          }).eq('id', goalId);
                        }
                      } catch (e) {
                        debugPrint("Goal update error: $e");
                      }
                    }
                  }

                  _amountCtrl.clear();
                  _noteCtrl.clear();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction saved!')),
                    );
                  }
                },
                isPrimary: true,
                isSuccess: true,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFC0FF00)
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'SAVE TRANSACTION',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection(
    BuildContext context,
    DateTime date,
    List<_TransactionItem> items,
  ) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final isToday = date == todayDate;
    final yesterday = todayDate.subtract(const Duration(days: 1));
    final dateLabel = isToday
        ? 'Today'
        : (date == yesterday
            ? 'Yesterday'
            : DateFormat('MMM d, y').format(date));
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              dateLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
          ...items.map(
            (item) => _TransactionTile(
              item: item,
              onDelete: item.isSample
                  ? null
                  : () => ref
                      .read(transactionListProvider.notifier)
                      .remove(item.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem {
  final String id;
  final String category;
  final String? note;
  final int amountCents;
  final DateTime? timestamp;
  final bool isSample;

  const _TransactionItem({
    required this.id,
    required this.category,
    this.note,
    required this.amountCents,
    this.timestamp,
    this.isSample = false,
  });
}

class _TransactionTile extends StatelessWidget {
  final _TransactionItem item;
  final VoidCallback? onDelete;

  const _TransactionTile({required this.item, this.onDelete});

  static const _primaryGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final isIncome = item.amountCents > 0;
    final amountColor = isIncome ? _primaryGreen : Colors.red.shade600;
    final icon =
        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      color: Theme.of(context).cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: amountColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: amountColor, size: 22),
        ),
        title: Text(
          item.note?.isNotEmpty == true ? item.note! : item.category,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          item.timestamp != null
              ? DateFormat('h:mm a').format(item.timestamp!)
              : '—',
          style: TextStyle(
            fontSize: 12,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? "+" : "-"}₱${(item.amountCents.abs() / 100).toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}
