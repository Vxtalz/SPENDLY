import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(transactionListProvider);
    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    if (txs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction History')),
        body: const Center(child: Text('No activity yet.')),
      );
    }

    final sortedTxs = [...txs]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, index) {
          final tx = sortedTxs[index];
          final amount = tx.amountCents.toDouble() / 100.0;
          final category = tx.category;
          final createdAt = tx.timestamp;

          final isIncome = amount > 0;
          final icon =
              isIncome ? Icons.bookmark_add_outlined : Icons.credit_card;

          return ListTile(
            leading: Icon(
              icon,
              color: isIncome ? Colors.green : Colors.red,
            ),
            title: Text(category),
            subtitle: Text(() {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final itemDate =
                  DateTime(createdAt.year, createdAt.month, createdAt.day);
              final yesterday = today.subtract(const Duration(days: 1));

              if (itemDate == today) {
                return "Today, ${DateFormat.jm().format(createdAt.toLocal())}";
              }
              if (itemDate == yesterday) {
                return "Yesterday, ${DateFormat.jm().format(createdAt.toLocal())}";
              }
              return DateFormat.yMMMd().add_jm().format(createdAt.toLocal());
            }()),
            trailing: Text(
              currency.format(amount),
              style: TextStyle(
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: sortedTxs.length,
      ),
    );
  }
}
