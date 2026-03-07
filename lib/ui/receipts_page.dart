import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/receipt_provider.dart';

class ReceiptsPage extends ConsumerStatefulWidget {
  const ReceiptsPage({super.key});

  @override
  ConsumerState<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends ConsumerState<ReceiptsPage> {
  final _merchantCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receipts = ref.watch(receiptListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Resibo (Receipts)')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: receipts.length,
              itemBuilder: (context, i) {
                final r = receipts[i];
                return ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(r.merchant),
                  subtitle: Text('₱${(r.totalCents / 100).toStringAsFixed(2)} • ${r.timestamp.toLocal()}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(receiptListProvider.notifier).remove(r.id),
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
                TextField(
                  controller: _merchantCtrl,
                  decoration: const InputDecoration(labelText: 'Merchant/Store'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total Amount (₱)'),
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
                      final merchant = _merchantCtrl.text.trim();
                      final pesos = int.tryParse(_amountCtrl.text.trim());
                      if (merchant.isEmpty || pesos == null || pesos <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid details')));
                        return;
                      }
                      await ref.read(receiptListProvider.notifier).add(
                            merchant: merchant,
                            totalCents: pesos * 100,
                            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                          );
                      _merchantCtrl.clear();
                      _amountCtrl.clear();
                      _noteCtrl.clear();
                    },
                    child: const Text('Add Receipt'),
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
