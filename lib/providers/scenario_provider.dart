import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

final scenarioPacksProvider =
    StateNotifierProvider<ScenarioPacksNotifier, List<ScenarioPack>>((ref) {
  return ScenarioPacksNotifier()..load();
});

class ScenarioPacksNotifier extends StateNotifier<List<ScenarioPack>> {
  ScenarioPacksNotifier() : super(const []);

  static const _prefsKey = 'scenario_packs_v1';

  List<ScenarioPack> get _defaults => [
        const ScenarioPack(
          id: 'debt_trap',
          title: 'The Interest Trap',
          topic: 'Debt & Interest',
          modules: [
            ScenarioModule(
                id: 'debt_temptation',
                title: 'The Tempting Upgrade',
                description:
                    'A shiny new phone is calling your name. Monthly installment or cold cash?'),
            ScenarioModule(
                id: 'debt_monster',
                title: 'The 0% Interest Myth',
                description:
                    'Is it really free? Uncover the hidden fees and the growth of the Debt Monster.'),
            ScenarioModule(
                id: 'debt_escape',
                title: 'Escape the Spiral',
                description:
                    'The balance is rising! Strategize your payments before the interest traps you.'),
          ],
        ),
        const ScenarioPack(
          id: 'savings_fort',
          title: 'The Emergency Fort',
          topic: 'Savings Basics',
          modules: [
            ScenarioModule(
                id: 'save_storm',
                title: 'The Storm is Coming',
                description:
                    'A sudden phone repair is approaching. Is your fort strong enough?'),
            ScenarioModule(
                id: 'save_first',
                title: 'Pay Yourself First',
                description:
                    'Intercept your salary before the bills steal it all!'),
          ],
        ),
        const ScenarioPack(
          id: 'scam_wars',
          title: 'Scambuster: SMS Wars',
          topic: 'Scam Awareness',
          modules: [
            ScenarioModule(
                id: 'scam_phish',
                title: 'Spot the Phish',
                description:
                    'Identify the fake GCash message before it drains your wallet.'),
          ],
        ),
        const ScenarioPack(
          id: 'insurance_net',
          title: 'The Safety Net Challenge',
          topic: 'Insurance 101',
          modules: [
            ScenarioModule(
                id: 'insurance_tightrope',
                title: 'The Tightrope Walk',
                description:
                    'Life hurdles are falling! Deploy your insurance net to stay safe.'),
          ],
        ),
        const ScenarioPack(
          id: 'investment_speed',
          title: 'Investment Speedrun',
          topic: 'Investment Basics',
          modules: [
            ScenarioModule(
                id: 'invest_race',
                title: 'Risk vs Return Race',
                description:
                    'Balance your speed (return) against the obstacles (risk).'),
          ],
        ),
        const ScenarioPack(
          id: 'salary_survival',
          title: '15-30 Survival Mode',
          topic: 'Managing First Salary',
          modules: [
            ScenarioModule(
                id: 'salary_libre',
                title: 'The "Libre" Gauntlet',
                description:
                    'Survive the pressure of friends asking for treats on payday.'),
          ],
        ),
        const ScenarioPack(
          id: 'insurance_awareness_pro',
          title: 'Insurance Pro (Ages 20-25)',
          topic: 'Insurance Awareness',
          modules: [
            ScenarioModule(
                id: 'insurance_horror',
                title: 'Hospital Horror Story',
                description: 'Experience an emergency with zero coverage.'),
            ScenarioModule(
                id: 'insurance_peace',
                title: 'The Peace of Mind',
                description:
                    'See the difference when a net is waiting for you.'),
          ],
        ),
      ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      state = _defaults;
      await _persist();
    } else {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => ScenarioPack.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    }
  }

  Future<void> markModuleCompleted(String moduleId) async {
    final next = state
        .map((pack) => ScenarioPack(
              id: pack.id,
              title: pack.title,
              topic: pack.topic,
              modules: pack.modules
                  .map(
                      (m) => m.id == moduleId ? m.copyWith(completed: true) : m)
                  .toList(),
            ))
        .toList();
    state = next;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
}
