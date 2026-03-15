import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  DateTime? _filterDate;

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(transactionListProvider);
    
    final byDate = <DateTime, List<_HistoryItem>>{};
    for (final t in txs) {
      final d = DateTime(t.timestamp.year, t.timestamp.month, t.timestamp.day);
      byDate.putIfAbsent(d, () => []).add(
            _HistoryItem(
              id: t.id,
              category: t.category,
              note: t.note,
              amountCents: t.amountCents,
              timestamp: t.timestamp,
              type: t.type,
            ),
          );
    }
    for (final list in byDate.values) {
      list.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));
    }
    final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        elevation: 0,
      ),
      body: txs.isEmpty
          ? const Center(child: Text('No activity yet.'))
          : Column(
              children: [
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
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
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
                            icon: const Icon(Icons.calendar_month, color: const Color(0xFF22C55E), size: 20),
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
                    children: sortedDates.where((d) {
                      if (_filterDate != null) {
                        return d.year == _filterDate!.year &&
                            d.month == _filterDate!.month &&
                            d.day == _filterDate!.day;
                      }
                      return true;
                    }).map((date) => _buildDateSection(context, ref, date, byDate[date]!)).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDateSection(BuildContext context, WidgetRef ref, DateTime date, List<_HistoryItem> items) {
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          ...items.map(
            (item) => _HistoryTile(
              item: item,
              onDelete: () => ref.read(transactionListProvider.notifier).remove(item.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem {
  final String id;
  final String category;
  final String? note;
  final int amountCents;
  final DateTime? timestamp;
  final String type;

  const _HistoryItem({
    required this.id,
    required this.category,
    this.note,
    required this.amountCents,
    this.timestamp,
    required this.type,
  });
}

class _HistoryTile extends StatelessWidget {
  final _HistoryItem item;
  final VoidCallback? onDelete;

  const _HistoryTile({required this.item, this.onDelete});

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
