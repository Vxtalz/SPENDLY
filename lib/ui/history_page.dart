import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _txs = [];
  final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  @override
  void initState() {
    super.initState();
    _loadTxs();
  }

  Future<void> _loadTxs() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;

    final data = await client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    if (mounted) {
      setState(() {
        _txs = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_txs.isEmpty) {
      return const Center(child: Text('No activity yet.'));
    }

    return RefreshIndicator(
      onRefresh: _loadTxs,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, index) {
          final tx = _txs[index];
          final amount = (tx['amount'] as num).toDouble();
          final type = tx['type'] as String;
          final category = tx['category'] as String;
          final createdAt = DateTime.parse(tx['created_at'] as String);

          final isIncome = amount > 0;
          final icon = switch (type) {
            'saving' => Icons.bookmark_add_outlined,
            'expense' => Icons.credit_card,
            _ => Icons.circle,
          };

          return ListTile(
            leading: Icon(
              icon,
              color: isIncome ? Colors.green : Colors.red,
            ),
            title: Text(category),
            subtitle: Text(
              DateFormat.yMMMd().add_jm().format(createdAt.toLocal()),
            ),
            trailing: Text(
              _currency.format(amount),
              style: TextStyle(
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: _txs.length,
      ),
    );
  }
}

