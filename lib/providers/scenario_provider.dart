import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

final scenarioPacksProvider = StateNotifierProvider<ScenarioPacksNotifier, List<ScenarioPack>>((ref) {
  return ScenarioPacksNotifier()..load();
});

class ScenarioPacksNotifier extends StateNotifier<List<ScenarioPack>> {
  ScenarioPacksNotifier() : super(const []);

  static const _prefsKey = 'scenario_packs_v1';

  List<ScenarioPack> get _defaults => [
        ScenarioPack(
          id: 'debt_borrowing',
          title: 'Debt and Borrowing',
          topic: 'Debt and Borrowing',
          modules: const [
            ScenarioModule(id: 'debt_intro', title: 'Understanding Interest', description: 'Learn interest basics'),
            ScenarioModule(id: 'debt_choices', title: 'Good vs Bad Debt', description: 'Decide when to borrow'),
          ],
        ),
        ScenarioPack(
          id: 'savings_basics',
          title: 'Savings Basics',
          topic: 'Savings Basics',
          modules: const [
            ScenarioModule(id: 'savings_pay_yourself', title: 'Pay Yourself First', description: 'Set aside savings first'),
            ScenarioModule(id: 'savings_emergency', title: 'Emergency Fund', description: 'Build a cushion'),
          ],
        ),
        ScenarioPack(
          id: 'scam_awareness',
          title: 'Scam Awareness',
          topic: 'Scam Awareness',
          modules: const [
            ScenarioModule(id: 'scam_red_flags', title: 'Spotting Red Flags', description: 'Avoid scams'),
          ],
        ),
        ScenarioPack(
          id: 'insurance_101',
          title: 'Insurance 101',
          topic: 'Insurance 101',
          modules: const [
            ScenarioModule(id: 'insurance_risk', title: 'Risk Pooling', description: 'How insurance works'),
          ],
        ),
        ScenarioPack(
          id: 'investment_basics',
          title: 'Investment Basics',
          topic: 'Investment Basics',
          modules: const [
            ScenarioModule(id: 'invest_risk_return', title: 'Risk vs Return', description: 'Finding balance'),
          ],
        ),
        ScenarioPack(
          id: 'first_salary',
          title: 'Managing Your First Salary',
          topic: 'Managing Your First Salary',
          modules: const [
            ScenarioModule(id: 'salary_budget', title: 'Your First Budget', description: '50/30/20 rule'),
          ],
        ),
        ScenarioPack(
          id: 'insurance_awareness_20_25',
          title: 'Insurance Awareness (Ages 20-25)',
          topic: 'Insurance Awareness',
          modules: const [
            ScenarioModule(id: 'no_insurance_case', title: 'Without Insurance', description: 'Simulate no coverage'),
            ScenarioModule(id: 'with_insurance_case', title: 'With Insurance', description: 'Compare with coverage'),
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
                  .map((m) => m.id == moduleId ? m.copyWith(completed: true) : m)
                  .toList(),
            ))
        .toList();
    state = next;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
}
