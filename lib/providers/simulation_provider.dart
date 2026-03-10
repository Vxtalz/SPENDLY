import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';

final simulationProvider =
    StateNotifierProvider<SimulationNotifier, SimulationState>((ref) {
  return SimulationNotifier()..load();
});

class SimulationNotifier extends StateNotifier<SimulationState> {
  SimulationNotifier() : super(const SimulationState());

  static const _prefsKey = 'simulation_state_v1';
  final _supabase = Supabase.instance.client;

  Future<void> load() async {
    // 1. Load from local cache first (Immediate offline support)
    final prefs = await SharedPreferences.getInstance();

    final userPersonType = prefs.getString('user_person_type');

    final localRaw = prefs.getString(_prefsKey);
    if (localRaw != null) {
      final parsed = SimulationState.fromJson(jsonDecode(localRaw));
      state = parsed.copyWith(todayType: parsed.todayType ?? userPersonType);
    } else {
      state = SimulationState(todayType: userPersonType);
    }

    // 2. Try to sync from Supabase if authenticated
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('simulation_state')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (response != null) {
          final remoteState = SimulationState.fromJson(response);
          // Simple conflict resolution: Remote wins if we just logged in,
          // or if it's the first time loading.
          // For a true offline app, we'd check 'updated_at' timestamps.
          state = remoteState.copyWith(
              todayType: remoteState.todayType ?? userPersonType);
          await _persistLocal();
        } else {
          // If remote doesn't exist, push local state to remote
          await _syncToRemote();
        }
      } catch (e) {
        // Offline or Supabase error - perfectly fine, we use local state
        debugPrint("Simulation load: working offline. $e");
      }
    }
  }

  Future<void> updateState(SimulationState newState) async {
    state = newState;
    await _persistLocal();
    await _syncToRemote();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  Future<void> _syncToRemote() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().substring(0, 10);

      await _supabase.from('simulation_state').upsert({
        'user_id': user.id,
        'balance': state.balance,
        'savings': state.savings,
        'debt': state.debt,
        'current_day': state.currentDay,
        'cycle_number': state.cycleNumber,
        'streak_days': state.streakDays,
        'last_played_date':
            state.lastPlayedDate?.toIso8601String().substring(0, 10) ??
                todayStr,
        'today_goal': state.todayGoal,
        'today_type': state.todayType,
        'today_allowance': state.todayAllowance,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail if offline. The local state is already persisted.
      debugPrint("Simulation sync: deferred (offline). $e");
    }
  }

  // Utility methods moved from UI to Provider
  Future<void> logExpense(double amount) async {
    final next = state.copyWith(balance: state.balance - amount);
    await updateState(next);
  }

  Future<void> logSaving(double amount) async {
    final next = state.copyWith(
      balance: state.balance - amount,
      savings: state.savings + amount,
    );
    await updateState(next);
  }

  Future<void> nextDay() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int newStreak = state.streakDays;
    if (state.lastPlayedDate == null) {
      newStreak = 1;
    } else {
      final diff = todayDate.difference(state.lastPlayedDate!).inDays;
      if (diff == 1) {
        newStreak += 1;
      } else if (diff > 1) {
        newStreak = 1;
      }
    }

    int nextDay = state.currentDay + 1;
    int nextCycle = state.cycleNumber;
    if (nextDay > 30) {
      nextDay = 1;
      nextCycle += 1;
    }

    double allowance = 300.0;
    if (newStreak >= 10) {
      allowance *= 1.2;
    } else if (newStreak >= 5) {
      allowance *= 1.1;
    }

    double newBalance = state.balance + allowance;
    if (nextDay == 1 && state.debt > 0) {
      newBalance -= (state.debt * 0.1); // Monthly interest
    }

    final next = state.copyWith(
      currentDay: nextDay,
      cycleNumber: nextCycle,
      streakDays: newStreak,
      lastPlayedDate: todayDate,
      balance: newBalance,
      todayGoal: null,
      todayType: null,
      todayAllowance: allowance,
    );

    await updateState(next);
  }
}
