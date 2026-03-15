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

enum _TxType { income, expense, save }

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'Income');
  final _noteCtrl = TextEditingController();
  _TxType _selectedType = _TxType.income;
  List<Map<String, dynamic>> _userGoals = [];
  DateTime? _filterDate;

  static const _primaryGreen = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _loadUserGoals();
  }

  Future<void> _loadUserGoals() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await client
          .from('goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _userGoals = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

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

    int totalIncomeActual = 0;
    int totalSaved = 0;
    int totalExpense = 0;
    for (final t in txs) {
      if (!t.timestamp.isBefore(startOfDay) && t.timestamp.isBefore(endOfDay)) {
        if (t.amountCents > 0) {
          if (t.type == 'save') {
            totalSaved += t.amountCents;
          } else {
            totalIncomeActual += t.amountCents;
          }
        } else {
          totalExpense += -t.amountCents;
        }
      }
    }
    final displayIncome = totalIncomeActual;

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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.arrow_downward_rounded,
                                    color: _primaryGreen, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Incoming',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: onSurface.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '₱${(displayIncome / 100).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: dividerColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.savings_outlined,
                                    color: Color(0xFFC0FF00), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Saved',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '₱${(totalSaved / 100).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC0FF00),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: dividerColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.arrow_upward_rounded,
                                    color: Colors.red.shade400, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Expenses',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: onSurface.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '₱${(totalExpense / 100).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade400,
                                ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _filterDate == null
                    ? 'Records'
                    : 'Filtered: ${DateFormat('MMM d, yyyy').format(_filterDate!)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: onSurface.withValues(alpha: 0.8),
                ),
              ),
              Row(
                children: [
                  if (_filterDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _filterDate = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month, color: _primaryGreen, size: 20),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _filterDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _filterDate = date);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              if (_filterDate == null ||
                  (startOfDay.year == _filterDate!.year &&
                      startOfDay.month == _filterDate!.month &&
                      startOfDay.day == _filterDate!.day))
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
                          type: t.type,
                          isSample: false,
                        ),
                      )
                      .toList(),
                ),
              ...sortedDates.where((d) {
                if (_filterDate != null) {
                  return d.year == _filterDate!.year &&
                      d.month == _filterDate!.month &&
                      d.day == _filterDate!.day &&
                      d != startOfDay;
                }
                return d != startOfDay;
              }).map(
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
                              type: t.type,
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
              SegmentedButton<_TxType>(
                segments: const [
                  ButtonSegment(
                    value: _TxType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                  ButtonSegment(
                    value: _TxType.save,
                    label: Text('Save'),
                    icon: Icon(Icons.savings_outlined),
                  ),
                  ButtonSegment(
                    value: _TxType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (val) {
                  setState(() {
                    _selectedType = val.first;
                    if (_selectedType == _TxType.expense) {
                      _categoryCtrl.text = 'Expense';
                    } else if (_selectedType == _TxType.income) {
                      _categoryCtrl.text = 'Income';
                    } else if (_selectedType == _TxType.save) {
                      _categoryCtrl.text = 'Saving';
                    }
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: _selectedType == _TxType.expense
                      ? Colors.red.withValues(alpha: 0.1)
                      : _selectedType == _TxType.income
                          ? _primaryGreen.withValues(alpha: 0.1)
                          : const Color(0xFFC0FF00).withValues(alpha: 0.1),
                  selectedForegroundColor: _selectedType == _TxType.expense
                      ? Colors.red
                      : _selectedType == _TxType.income
                          ? _primaryGreen
                          : const Color(0xFFC0FF00),
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
                      decoration: InputDecoration(
                        labelText: 'Category',
                        suffixIcon: (_selectedType == _TxType.save && _userGoals.isNotEmpty)
                            ? PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (value) {
                                  _categoryCtrl.text = value;
                                },
                                itemBuilder: (context) {
                                  return [
                                    const PopupMenuItem(
                                      value: 'General Saving',
                                      child: Text('General Saving'),
                                    ),
                                    ..._userGoals.map((g) => PopupMenuItem(
                                          value: g['name'] as String,
                                          child: Text(g['name'] as String),
                                        ))
                                  ];
                                },
                              )
                            : null,
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

                  final amountCents = _selectedType == _TxType.expense
                      ? -(pesos * 100)
                      : (pesos * 100);

                  final simNotifier = ref.read(simulationProvider.notifier);
                  final txNotifier = ref.read(transactionListProvider.notifier);

                  if (_selectedType == _TxType.expense) {
                    await simNotifier.logExpense(pesos.toDouble());
                  } else if (_selectedType == _TxType.save) {
                    await simNotifier.logSaving(pesos.toDouble());
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
                    type: _selectedType.name,
                  );

                  // If it's income or savings, let's treat it as progress towards our goal
                  if (_selectedType != _TxType.expense) {
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

                  if (context.mounted) {
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
    if (items.isEmpty) return const SizedBox.shrink();

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
  final String type;
  final bool isSample;

  const _TransactionItem({
    required this.id,
    required this.category,
    this.note,
    required this.amountCents,
    this.timestamp,
    required this.type,
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
    final isSavings = item.type == 'save';
    final amountColor = isSavings
        ? const Color(0xFFC0FF00)
        : isIncome
            ? _primaryGreen
            : Colors.red.shade600;

    final icon = isSavings
        ? Icons.savings_outlined
        : isIncome
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;

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
          item.category,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.note?.isNotEmpty == true) ...[
              Text(
                item.note!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              item.timestamp != null
                  ? DateFormat('h:mm a').format(item.timestamp!)
                  : '—',
              style: TextStyle(
                fontSize: 12,
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
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
