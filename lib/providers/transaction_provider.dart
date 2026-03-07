import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';

final transactionListProvider = StateNotifierProvider<TransactionNotifier, List<TransactionEntry>>((ref) {
  return TransactionNotifier()..load();
});

class TransactionNotifier extends StateNotifier<List<TransactionEntry>> {
  TransactionNotifier() : super(const []);

  static const _prefsKey = 'transactions_v1';
  final _uuid = const Uuid();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      state = const [];
    } else {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => TransactionEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    }
  }

  Future<void> add({
    required int amountCents,
    required String category,
    String? note,
    DateTime? timestamp,
    String? receiptId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = TransactionEntry(
      id: _uuid.v4(),
      amountCents: amountCents,
      category: category,
      timestamp: timestamp ?? DateTime.now(),
      note: note,
      receiptId: receiptId,
    );
    final next = [...state, entry];
    state = next;
    await prefs.setString(_prefsKey, jsonEncode(next.map((e) => e.toJson()).toList()));
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final next = state.where((e) => e.id != id).toList();
    state = next;
    await prefs.setString(_prefsKey, jsonEncode(next.map((e) => e.toJson()).toList()));
  }

  int totalBetween(DateTime from, DateTime to) {
    return state
        .where((e) => !e.timestamp.isBefore(from) && e.timestamp.isBefore(to))
        .fold(0, (sum, e) => sum + e.amountCents);
  }
}
