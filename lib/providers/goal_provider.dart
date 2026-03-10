import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

final goalProvider = StateNotifierProvider<GoalNotifier, SpendGoal?>((ref) {
  return GoalNotifier()..load();
});

class GoalNotifier extends StateNotifier<SpendGoal?> {
  GoalNotifier() : super(null);

  static const _prefsKey = 'spend_goal_v1';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      state = null;
    } else {
      state = SpendGoal.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
  }

  Future<void> setGoal(GoalPeriod period, int amountCents) async {
    final prefs = await SharedPreferences.getInstance();
    final g = SpendGoal(
        period: period, amountCents: amountCents, startAt: DateTime.now());
    state = g;
    await prefs.setString(_prefsKey, jsonEncode(g.toJson()));
  }

  Future<void> clearGoal() async {
    final prefs = await SharedPreferences.getInstance();
    state = null;
    await prefs.remove(_prefsKey);
  }

  Future<void> addSpending(int cents) async {
    final prefs = await SharedPreferences.getInstance();
    final g = state;
    if (g == null) return;
    final updated = g.copyWith(spentCents: g.spentCents + cents);
    state = updated;
    await prefs.setString(_prefsKey, jsonEncode(updated.toJson()));
  }

  Future<void> completeIfPeriodEnded() async {
    final prefs = await SharedPreferences.getInstance();
    final g = state;
    if (g == null) return;
    if (DateTime.now().isAfter(g.periodEnd)) {
      final updated = g.copyWith(completed: true);
      state = updated;
      await prefs.setString(_prefsKey, jsonEncode(updated.toJson()));
    }
  }
}
