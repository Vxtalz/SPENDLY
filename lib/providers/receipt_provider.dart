import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';

final receiptListProvider = StateNotifierProvider<ReceiptNotifier, List<ReceiptEntry>>((ref) {
  return ReceiptNotifier()..load();
});

class ReceiptNotifier extends StateNotifier<List<ReceiptEntry>> {
  ReceiptNotifier() : super(const []);

  static const _prefsKey = 'receipts_v1';
  final _uuid = const Uuid();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      state = const [];
    } else {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => ReceiptEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    }
  }

  Future<String> add({
    required String merchant,
    required int totalCents,
    String? imagePath,
    String? note,
    DateTime? timestamp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final id = _uuid.v4();
    final entry = ReceiptEntry(
      id: id,
      merchant: merchant,
      totalCents: totalCents,
      timestamp: timestamp ?? DateTime.now(),
      imagePath: imagePath,
      note: note,
    );
    final next = [...state, entry];
    state = next;
    await prefs.setString(_prefsKey, jsonEncode(next.map((e) => e.toJson()).toList()));
    return id;
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final next = state.where((e) => e.id != id).toList();
    state = next;
    await prefs.setString(_prefsKey, jsonEncode(next.map((e) => e.toJson()).toList()));
  }
}
