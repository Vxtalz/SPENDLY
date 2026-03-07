import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

final entitlementProvider = StateNotifierProvider<EntitlementNotifier, EntitlementState?>((ref) {
  return EntitlementNotifier()..load();
});

class EntitlementNotifier extends StateNotifier<EntitlementState?> {
  EntitlementNotifier() : super(null);

  static const _prefsKey = 'entitlement_state_v1';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      // Start 30-day trial on first run
      final s = EntitlementState(trialStartedAt: DateTime.now(), premium: false);
      state = s;
      await prefs.setString(_prefsKey, jsonEncode(s.toJson()));
    } else {
      state = EntitlementState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final current = state;
    if (current == null) return;
    final next = EntitlementState(trialStartedAt: current.trialStartedAt, premium: value);
    state = next;
    await prefs.setString(_prefsKey, jsonEncode(next.toJson()));
  }

  bool canAccessPremiumFeature() {
    final s = state;
    if (s == null) return false;
    return s.isPremium; // trial or purchased
  }
}
