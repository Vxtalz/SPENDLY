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

  static const _prefsKey = 'scenario_packs_v2';

  List<ScenarioPack> get _defaults => [
        const ScenarioPack(
          id: 'debt_trap',
          title: 'The Interest Trap',
          topic: 'Debt & Interest',
          modules: [
            ScenarioModule(
                id: 'debt_temptation',
                title: 'Unit 1: The Tempting Upgrade',
                description: 'A shiny new phone is calling your name. Monthly installment or cold cash?'),
            ScenarioModule(
                id: 'debt_monster',
                title: 'Unit 2: The 0% Interest Myth',
                description: 'Is it really free? Uncover the hidden fees.'),
            ScenarioModule(
                id: 'debt_payday',
                title: 'Unit 3: The Payday Pitfall',
                description: 'Short on cash? The fast cash app wants 10% monthly interest.'),
            ScenarioModule(
                id: 'debt_card',
                title: 'Unit 4: The Credit Card Swiper',
                description: 'Swipe now, pay later. But the minimum payment is deceptive.'),
            ScenarioModule(
                id: 'debt_escape',
                title: 'Unit 5: Escape the Spiral',
                description: 'The balance is rising! Strategize your payments.'),
          ],
        ),
        const ScenarioPack(
          id: 'savings_fort',
          title: 'The Emergency Fort',
          topic: 'Savings Basics',
          modules: [
            ScenarioModule(
                id: 'save_storm',
                title: 'Unit 1: The Storm is Coming',
                description: 'A sudden phone repair is approaching. Is your fort strong enough?'),
            ScenarioModule(
                id: 'save_first',
                title: 'Unit 2: Pay Yourself First',
                description: 'Intercept your salary before the bills steal it all!'),
            ScenarioModule(
                id: 'save_creep',
                title: 'Unit 3: Lifestyle Creep',
                description: 'You got a raise! Do you upgrade your coffee or your fort?'),
            ScenarioModule(
                id: 'save_want',
                title: 'Unit 4: Emergency vs Want',
                description: 'Sale on sneakers! Is this an emergency?'),
            ScenarioModule(
                id: 'save_compound',
                title: 'Unit 5: The Compound Effect',
                description: 'Time is money. See how your fort grows when left alone.'),
          ],
        ),
        const ScenarioPack(
          id: 'scam_wars',
          title: 'Scambuster: SMS Wars',
          topic: 'Scam Awareness',
          modules: [
            ScenarioModule(
                id: 'scam_phish',
                title: 'Unit 1: Spot the Phish',
                description: 'Identify the fake message before it drains your wallet.'),
            ScenarioModule(
                id: 'scam_crypto',
                title: 'Unit 2: The Crypto Guru',
                description: 'Guaranteed 200% returns in 3 days? Hmm...'),
            ScenarioModule(
                id: 'scam_prize',
                title: 'Unit 3: You Won a Prize!',
                description: 'You won a raffle you never entered.'),
            ScenarioModule(
                id: 'scam_pyramid',
                title: 'Unit 4: The "Networking" Pitche',
                description: 'Your old classmate wants you to sell soap for financial freedom.'),
            ScenarioModule(
                id: 'scam_store',
                title: 'Unit 5: The Fake Store',
                description: 'Shoes are 90% off on a weird website.'),
          ],
        ),
        const ScenarioPack(
          id: 'insurance_net',
          title: 'The Safety Net Challenge',
          topic: 'Insurance 101',
          modules: [
            ScenarioModule(
                id: 'insurance_tightrope',
                title: 'Unit 1: The Tightrope Walk',
                description: 'Life hurdles are falling! Deploy your net.'),
            ScenarioModule(
                id: 'insurance_peace',
                title: 'Unit 2: The Peace of Mind',
                description: 'See the difference when a net is waiting for you.'),
            ScenarioModule(
                id: 'insurance_deductible',
                title: 'Unit 3: Deductible Dilemma',
                description: 'Low premiums or low deductibles?'),
            ScenarioModule(
                id: 'insurance_life',
                title: 'Unit 4: Life Insurance Basics',
                description: 'Securing the future of your loved ones.'),
            ScenarioModule(
                id: 'insurance_vul',
                title: 'Unit 5: The Investment-Linked Trap',
                description: 'Insurance combined with investment. Is it worth it?'),
          ],
        ),
        const ScenarioPack(
          id: 'investment_speed',
          title: 'Investment Speedrun',
          topic: 'Investment Basics',
          modules: [
            ScenarioModule(
                id: 'invest_race',
                title: 'Unit 1: Risk vs Return Race',
                description: 'Balance your speed (return) against the obstacles (risk).'),
            ScenarioModule(
                id: 'invest_diversify',
                title: 'Unit 2: Diversification Dash',
                description: 'Don\'t put all your eggs in one rocket.'),
            ScenarioModule(
                id: 'invest_inflation',
                title: 'Unit 3: The Inflation Monster',
                description: 'Your cash is losing power. Invest to beat it.'),
            ScenarioModule(
                id: 'invest_dip',
                title: 'Unit 4: Buying the Dip',
                description: 'The market crashed! Do you panic sell or buy more?'),
            ScenarioModule(
                id: 'invest_time',
                title: 'Unit 5: Time In The Market',
                description: 'Timing the market vs Time in the market.'),
          ],
        ),
        const ScenarioPack(
          id: 'salary_survival',
          title: '15-30 Survival Mode',
          topic: 'Managing First Salary',
          modules: [
            ScenarioModule(
                id: 'salary_libre',
                title: 'Unit 1: The "Libre" Gauntlet',
                description: 'Survive the pressure of friends asking for treats on payday.'),
            ScenarioModule(
                id: 'salary_rule',
                title: 'Unit 2: The 50-30-20 Rule',
                description: 'Divide your salary before it vanishes.'),
            ScenarioModule(
                id: 'salary_subs',
                title: 'Unit 3: The Subscription Drain',
                description: 'Find and eliminate the vampire apps sucking your wallet.'),
            ScenarioModule(
                id: 'salary_hustle',
                title: 'Unit 4: Side Hustle Energy',
                description: 'Use your weekends to boost your income.'),
            ScenarioModule(
                id: 'salary_tax',
                title: 'Unit 5: Tax Realities',
                description: 'Gross vs Net Income shock!'),
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
