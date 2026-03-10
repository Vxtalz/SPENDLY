import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import '../providers/simulation_provider.dart';
import 'widgets/interactive_widgets.dart';

class SimulationPage extends ConsumerStatefulWidget {
  const SimulationPage({super.key});

  @override
  ConsumerState<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends ConsumerState<SimulationPage> {
  final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  String? _selectedChoiceId;
  String? _consequenceText;
  bool _isSuccess = false;
  Map<String, dynamic>? _currentScenario;

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  Map<String, dynamic> _generateScenario(String todayType, double allowance) {
    // Generate ranges based on allowance
    double minAmt = 10;
    double maxAmt = 50;
    if (allowance <= 100) {
      minAmt = 10;
      maxAmt = 50;
    } else if (allowance <= 300) {
      minAmt = 15;
      maxAmt = 100;
    } else if (allowance <= 600) {
      minAmt = 50;
      maxAmt = 200;
    } else {
      minAmt = 100;
      maxAmt = 500;
    }

    final List<Map<String, dynamic>> homeScenarios = [
      {
        'title': 'Restocking the Pantry',
        'desc': 'Buy groceries for the house or wait for parents?',
        'spendLabel': 'Buy Groceries',
        'spendIcon': Icons.shopping_cart,
        'saveLabel': 'Wait for Parents',
        'saveIcon': Icons.home,
        'emoji': '🏠',
      },
      {
        'title': 'Online Sale Alert',
        'desc': 'Online shopping notification — buy or ignore?',
        'spendLabel': 'Buy Sale Item',
        'spendIcon': Icons.shopping_bag,
        'saveLabel': 'Ignore Alert',
        'saveIcon': Icons.notifications_off,
        'emoji': '📱',
      },
      {
        'title': 'Cravings at Home',
        'desc': 'Order food delivery or cook what is available?',
        'spendLabel': 'Order Delivery',
        'spendIcon': Icons.delivery_dining,
        'saveLabel': 'Cook at Home',
        'saveIcon': Icons.kitchen,
        'emoji': '🍲',
      },
      {
        'title': 'Internet Top-up',
        'desc': 'Load up for mobile data or use home WiFi?',
        'spendLabel': 'Buy Data Promo',
        'spendIcon': Icons.signal_cellular_alt,
        'saveLabel': 'Use Home WiFi',
        'saveIcon': Icons.wifi,
        'emoji': '📶'
      },
      {
        'title': 'Sibling Request',
        'desc': 'Sibling asks for money for something small.',
        'spendLabel': 'Give Money',
        'spendIcon': Icons.wallet_giftcard,
        'saveLabel': 'Say No Today',
        'saveIcon': Icons.front_hand,
        'emoji': '👧'
      }
    ];

    final List<Map<String, dynamic>> schoolScenarios = [
      {
        'title': 'Getting to School',
        'desc': 'Jeepney is right there. Or you can walk.',
        'spendLabel': 'Ride Jeepney',
        'spendIcon': Icons.directions_bus,
        'saveLabel': 'Walk to School',
        'saveIcon': Icons.directions_walk,
        'emoji': '🚌'
      },
      {
        'title': 'Lunchtime Decision',
        'desc':
            'Your packed lunch is at home. Cafeteria meal is right in front of you.',
        'spendLabel': 'Buy Cafeteria Meal',
        'spendIcon': Icons.restaurant,
        'saveLabel': 'Skip and Wait',
        'saveIcon': Icons.timer,
        'emoji': '🍱'
      },
      {
        'title': 'Project Research',
        'desc': 'Load up phone or use free school WiFi?',
        'spendLabel': 'Buy Load',
        'spendIcon': Icons.phone_android,
        'saveLabel': 'Connect to WiFi',
        'saveIcon': Icons.wifi,
        'emoji': '💻'
      },
      {
        'title': 'Borrowing Money',
        'desc': 'A friend wants to borrow money for a project.',
        'spendLabel': 'Lend Money',
        'spendIcon': Icons.handshake,
        'saveLabel': 'Explain You Cannot',
        'saveIcon': Icons.speaker_notes_off,
        'emoji': '🤝'
      },
      {
        'title': 'Afternoon Hunger',
        'desc': 'Snack from canteen or skip it?',
        'spendLabel': 'Buy Snack',
        'spendIcon': Icons.fastfood,
        'saveLabel': 'Skip Snack',
        'saveIcon': Icons.no_food,
        'emoji': '🍿'
      }
    ];

    final List<Map<String, dynamic>> workScenarios = [
      {
        'title': 'Lunch Break',
        'desc': 'Eat out near work or bring a packed meal?',
        'spendLabel': 'Eat Out',
        'spendIcon': Icons.restaurant,
        'saveLabel': 'Packed Lunch',
        'saveIcon': Icons.lunch_dining,
        'emoji': '💼'
      },
      {
        'title': 'Morning Commute',
        'desc': 'Take a ride to work or commute longer route?',
        'spendLabel': 'Direct Ride',
        'spendIcon': Icons.local_taxi,
        'saveLabel': 'Long Commute',
        'saveIcon': Icons.directions_transit,
        'emoji': '🚖'
      },
      {
        'title': 'Energy Boost',
        'desc': 'Buy coffee to stay productive or skip?',
        'spendLabel': 'Buy Coffee',
        'spendIcon': Icons.coffee,
        'saveLabel': 'Drink Water',
        'saveIcon': Icons.water_drop,
        'emoji': '☕'
      },
      {
        'title': 'Team Bonding',
        'desc': 'Coworker asks to split a meal — join or eat alone?',
        'spendLabel': 'Join Co-workers',
        'spendIcon': Icons.group,
        'saveLabel': 'Eat Alone',
        'saveIcon': Icons.person,
        'emoji': '👥'
      },
      {
        'title': 'Extra Hours',
        'desc': 'Overtime opportunity — take it or rest?',
        'spendLabel': 'Go Home and Rest',
        'spendIcon': Icons.bed,
        'saveLabel': 'Take Overtime',
        'saveIcon': Icons.work_history,
        'emoji': '⏱️'
      }
    ];

    final List<Map<String, dynamic>> restScenarios = [
      {
        'title': 'Weekend Plans',
        'desc': 'Mall with friends — go or stay home?',
        'spendLabel': 'Go to Mall',
        'spendIcon': Icons.local_mall,
        'saveLabel': 'Stay Home',
        'saveIcon': Icons.home,
        'emoji': '🛍️'
      },
      {
        'title': 'Flash Sale',
        'desc': 'Online sale notification — buy or ignore?',
        'spendLabel': 'Check Out Cart',
        'spendIcon': Icons.shopping_cart_checkout,
        'saveLabel': 'Ignore App',
        'saveIcon': Icons.phonelink_erase,
        'emoji': '🔥'
      },
      {
        'title': 'Lazy Dinner',
        'desc': 'Order in or cook at home?',
        'spendLabel': 'Order Delivery',
        'spendIcon': Icons.motorcycle,
        'saveLabel': 'Cook Dinner',
        'saveIcon': Icons.soup_kitchen,
        'emoji': '🍕'
      },
      {
        'title': 'Digital Expenses',
        'desc': 'Subscriptions auto-renewing — keep or cancel?',
        'spendLabel': 'Keep Subscriptions',
        'spendIcon': Icons.subscriptions,
        'saveLabel': 'Cancel Subscriptions',
        'saveIcon': Icons.cancel,
        'emoji': '📺'
      },
      {
        'title': 'Sudden Invite',
        'desc': 'Friend invites out — spend on fare or decline?',
        'spendLabel': 'Meet Friend',
        'spendIcon': Icons.directions_car,
        'saveLabel': 'Decline Invite',
        'saveIcon': Icons.do_not_disturb,
        'emoji': '👋'
      }
    ];

    final List<Map<String, dynamic>> emergencyScenarios = [
      {
        'title': 'Unexpected Bill',
        'desc': 'Unexpected bill arrived — pay now or delay?',
        'spendLabel': 'Pay Bill Now',
        'spendIcon': Icons.receipt,
        'saveLabel': 'Delay Payment',
        'saveIcon': Icons.pending_actions,
        'emoji': '🧾'
      },
      {
        'title': 'Health Check',
        'desc': 'Medicine needed — buy immediately or wait?',
        'spendLabel': 'Buy Medicine',
        'spendIcon': Icons.medical_services,
        'saveLabel': 'Wait it Out',
        'saveIcon': Icons.hourglass_bottom,
        'emoji': '💊'
      },
      {
        'title': 'Family Support',
        'desc': 'Family member needs help — give or explain you cannot?',
        'spendLabel': 'Give Help',
        'spendIcon': Icons.volunteer_activism,
        'saveLabel': 'Explain Situation',
        'saveIcon': Icons.chat,
        'emoji': '👨‍👩‍👧‍👦'
      },
      {
        'title': 'Transport Hassle',
        'desc': 'Transportation emergency — spend more or find alternative?',
        'spendLabel': 'Spend on Transport',
        'spendIcon': Icons.taxi_alert,
        'saveLabel': 'Find Alternative',
        'saveIcon': Icons.alt_route,
        'emoji': '🚨'
      },
      {
        'title': 'Missed Day',
        'desc': 'Missed work/school — recover the day or rest?',
        'spendLabel': 'Rest and Recover',
        'spendIcon': Icons.healing,
        'saveLabel': 'Catch Up',
        'saveIcon': Icons.school,
        'emoji': '🤒'
      }
    ];

    List<Map<String, dynamic>> targetList = schoolScenarios;
    if (todayType.toLowerCase() == 'home')
      targetList = homeScenarios;
    else if (todayType.toLowerCase() == 'working' ||
        todayType.toLowerCase() == 'work' ||
        todayType.toLowerCase() == 'freelancer')
      targetList = workScenarios;
    else if (todayType.toLowerCase() == 'rest' ||
        todayType.toLowerCase() == 'out of school youth')
      targetList = restScenarios;
    else if (todayType.toLowerCase() == 'emergency')
      targetList = emergencyScenarios;

    targetList.shuffle();
    final template = targetList.first;

    // generate random amount in range
    final actualAmount =
        minAmt + (maxAmt - minAmt) * (DateTime.now().millisecond / 1000.0);
    // round to nearest 5
    final roundedAmount = (actualAmount / 5).round() * 5.0;

    return {
      ...template,
      'amount': roundedAmount,
    };
  }

  Future<void> _handleChoice(
      String id, String label, double amount, bool isSaving) async {
    if (_selectedChoiceId != null) return;

    final simState = ref.read(simulationProvider);
    final goal = simState.todayGoal;

    setState(() {
      _selectedChoiceId = id;
      _isSuccess = isSaving;

      double newRemaining = simState.balance + (isSaving ? 0 : -amount);
      if (goal == 'save_max') {
        _consequenceText = isSaving
            ? "Nice save! That ${_currency.format(amount)} stays with you."
            : "Spent ${_currency.format(amount)}. Still okay — just fewer decisions like this today.";
      } else if (goal == 'balanced') {
        _consequenceText = isSaving
            ? "Good move. Balance still looking healthy."
            : "Fair call. Just stay aware of what is left.";
      } else if (goal == 'stick_to_budget') {
        _consequenceText = isSaving
            ? "Nice! You kept your budget. Remaining: ${_currency.format(newRemaining)}"
            : (newRemaining <= 0)
                ? "That is your budget for today. No more spending — you planned for this."
                : (newRemaining < 30)
                    ? "Heads up — only ${_currency.format(newRemaining)} left. Make the next one count."
                    : "Remaining budget is ${_currency.format(newRemaining)}.";
      } else if (goal == 'have_purchase') {
        _consequenceText = isSaving
            ? "Smart move! Saving room for your planned purchase."
            : (newRemaining < 100)
                ? "You might not have enough left for what you planned. Next choice matters."
                : "You have ${_currency.format(newRemaining)} left. Remember you still have something to buy today.";
      } else {
        _consequenceText = isSaving
            ? "Great choice! Saving $label builds your future security."
            : "You spent $label. It's a treat, but remember your long-term goals!";
      }
    });

    final notifier = ref.read(simulationProvider.notifier);
    if (isSaving) {
      await notifier.logSaving(amount);
    } else {
      await notifier.logExpense(amount);
    }

    final client = Supabase.instance.client;
    final userId = _userId;
    if (userId != null) {
      try {
        await client.from('transactions').insert({
          'user_id': userId,
          'amount': isSaving ? amount : -amount,
          'category': isSaving ? 'savings' : 'daily_spend',
          'type': isSaving ? 'saving' : 'expense',
          'description': isSaving ? 'Saved from $label' : 'Spent on $label',
        });
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> _computeWeeklySummary() async {
    final client = Supabase.instance.client;
    if (_userId == null) return {'spent': 0.0, 'saved': 0.0};
    final fromDate = DateTime.now().subtract(const Duration(days: 7));
    try {
      final data = await client
          .from('transactions')
          .select()
          .eq('user_id', _userId!)
          .gte('created_at', fromDate.toIso8601String());
      double spent = 0;
      double saved = 0;
      for (final tx in data) {
        final amount = (tx['amount'] as num).toDouble();
        if (tx['type'] == 'expense') spent += -amount;
        if (tx['type'] == 'saving') saved += amount;
      }
      return {'spent': spent, 'saved': saved};
    } catch (_) {
      return {'spent': 0.0, 'saved': 0.0};
    }
  }

  Future<Map<String, dynamic>> _computeCycleSummary() async {
    final client = Supabase.instance.client;
    if (_userId == null) return {'spent': 0.0, 'saved': 0.0, 'debt': 0.0};
    final fromDate = DateTime.now().subtract(const Duration(days: 30));
    try {
      final txs = await client
          .from('transactions')
          .select()
          .eq('user_id', _userId!)
          .gte('created_at', fromDate.toIso8601String());
      double spent = 0;
      double saved = 0;
      for (final tx in txs) {
        final amount = (tx['amount'] as num).toDouble();
        if (tx['type'] == 'expense') spent += -amount;
        if (tx['type'] == 'saving') saved += amount;
      }
      return {
        'spent': spent,
        'saved': saved,
        'debt': ref.read(simulationProvider).debt
      };
    } catch (_) {
      return {'spent': 0.0, 'saved': 0.0, 'debt': 0.0};
    }
  }

  Future<void> _awardBadge(String key, String label) async {
    if (_userId == null) return;
    try {
      final client = Supabase.instance.client;
      final existing = await client
          .from('badges')
          .select()
          .eq('user_id', _userId!)
          .eq('badge_key', key)
          .maybeSingle();
      if (existing == null)
        await client
            .from('badges')
            .insert({'user_id': _userId!, 'badge_key': key, 'label': label});
    } catch (_) {}
  }

  Future<void> _showWeeklyReport() async {
    final summary = await _computeWeeklySummary();
    final spent = summary['spent'] as double;
    final saved = summary['saved'] as double;
    String message = spent > saved * 3
        ? 'Medyo magastos this week.'
        : 'Decent balance this week.';
    if (saved >= spent * 0.3) {
      message = 'Astig! You saved at least 30%.';
      await _awardBadge('weekly_saver', 'Weekly Saver');
    }
    if (!mounted) return;
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Weekly report'),
              content: Text(
                  'Spent: ₱${spent.toStringAsFixed(0)}\nSaved: ₱${saved.toStringAsFixed(0)}\n\n$message'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Okay'))
              ],
            ));
  }

  Future<void> _showCycleReport() async {
    final summary = await _computeCycleSummary();
    if (!mounted) return;
    final spent = summary['spent'] as double;
    final saved = summary['saved'] as double;
    final debt = summary['debt'] as double;
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('30-day summary'),
              content: Text(
                  'Spent: ₱${spent.toStringAsFixed(0)}\nSaved: ₱${saved.toStringAsFixed(0)}\nDebt: ₱${debt.toStringAsFixed(0)}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Next cycle'))
              ],
            ));
  }

  Future<void> _nextDay() async {
    final oldState = ref.read(simulationProvider);
    await ref.read(simulationProvider.notifier).nextDay();
    final newState = ref.read(simulationProvider);

    setState(() {
      _selectedChoiceId = null;
      _consequenceText = null;
      _currentScenario = null;
    });

    if (newState.currentDay == 1 &&
        newState.cycleNumber > oldState.cycleNumber) {
      await _showCycleReport();
    } else if (newState.currentDay % 7 == 1 && newState.currentDay != 1) {
      await _showWeeklyReport();
    }
    if (newState.streakDays == 30)
      await _awardBadge('perfect_streak', 'Perfect Streak');
  }

  Widget _buildGoalSelection(SimulationState simState) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'What are you going for today?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF6A5AE0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6A5AE0)),
          ),
          child: Column(
            children: [
              const Text(
                'Available Budget',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A5AE0),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currency.format(simState.todayAllowance),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A5AE0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _GoalCard(
          icon: '💰',
          label: 'Save as much as possible',
          onTap: () => _selectGoal('save_max', simState),
        ),
        const SizedBox(height: 12),
        _GoalCard(
          icon: '⚖️',
          label: 'Spend wisely, save a little',
          onTap: () => _selectGoal('balanced', simState),
        ),
        const SizedBox(height: 12),
        _GoalCard(
          icon: '🎯',
          label: 'Stick exactly to my budget',
          onTap: () => _selectGoal('stick_to_budget', simState),
        ),
        const SizedBox(height: 12),
        _GoalCard(
          icon: '🛒',
          label: 'I have something to buy today',
          onTap: () => _selectGoal('have_purchase', simState),
        ),
      ],
    );
  }

  Future<void> _selectGoal(String goalId, SimulationState simState) async {
    final notifier = ref.read(simulationProvider.notifier);
    final type = simState.todayType ?? 'school';
    await notifier
        .updateState(simState.copyWith(todayGoal: goalId, todayType: type));
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(simulationProvider);

    if (simState.todayGoal == null) {
      return _buildGoalSelection(simState);
    }

    if (_currentScenario == null) {
      final type = simState.todayType ?? 'school';
      _currentScenario = _generateScenario(type, simState.todayAllowance);
    }

    final s = _currentScenario!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6A5AE0), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF6A5AE0).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text('Your lifetime daily money companion',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1))),
              const SizedBox(height: 16),
              Text('Day ${simState.currentDay} of 30',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Stack(children: [
                Container(
                    height: 10,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(5))),
                FractionallySizedBox(
                    widthFactor: simState.currentDay / 30,
                    child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                            color: const Color(0xFFC0FF00),
                            borderRadius: BorderRadius.circular(5)))),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ]),
          child: Column(
            children: [
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(s['emoji'] as String,
                      style: const TextStyle(fontSize: 40))),
              const SizedBox(height: 16),
              Text(s['title'] as String,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(s['desc'] as String,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 16, color: Color(0xFF64748B))),
              const SizedBox(height: 28),
              _ChoiceTile(
                  id: 'spend_option',
                  icon: s['spendIcon'] as IconData,
                  label: s['spendLabel'] as String,
                  hint: 'Takes from budget',
                  cost: '- ${_currency.format(s['amount'])}',
                  color: Colors.redAccent,
                  isSelected: _selectedChoiceId == 'spend_option',
                  isSuccess: false,
                  onTap: () => _handleChoice('spend_option',
                      s['spendLabel'] as String, s['amount'] as double, false)),
              const SizedBox(height: 12),
              _ChoiceTile(
                  id: 'save_option',
                  icon: s['saveIcon'] as IconData,
                  label: s['saveLabel'] as String,
                  hint: 'Keep in budget',
                  cost: '+ ${_currency.format(s['amount'])} saved',
                  color: const Color(0xFFC0FF00),
                  isSelected: _selectedChoiceId == 'save_option',
                  isSuccess: true,
                  onTap: () => _handleChoice('save_option',
                      s['saveLabel'] as String, s['amount'] as double, true)),
              const SizedBox(height: 24),
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                child: _consequenceText == null
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: _isSuccess
                                ? const Color(0xFFC0FF00).withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _isSuccess
                                    ? const Color(0xFFC0FF00)
                                        .withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3))),
                        child: Row(children: [
                          Icon(
                              _isSuccess
                                  ? Icons.check_circle
                                  : Icons.info_outline,
                              color: _isSuccess
                                  ? const Color(0xFF1B5E20)
                                  : Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(_consequenceText!,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _isSuccess
                                          ? const Color(0xFF1B5E20)
                                          : Colors.red))),
                        ]),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: InteractiveButton(
              isPrimary: true,
              onTap: _nextDay,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20)),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFFC0FF00)),
                  const SizedBox(width: 12),
                  const Text('NEXT DAY',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1)),
                ]),
              )),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _MiniStat(
                label: 'Wallet',
                value: _currency.format(simState.balance),
                color: Theme.of(context).colorScheme.onSurface),
            _MiniStat(
                label: 'Savings',
                value: _currency.format(simState.savings),
                color: const Color(0xFF6A5AE0)),
            _MiniStat(
                label: 'Streak',
                value: '${simState.streakDays} Days',
                color: Theme.of(context).colorScheme.onSurface),
          ],
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String id, label, hint, cost;
  final IconData icon;
  final Color color;
  final bool isSelected, isSuccess;
  final VoidCallback onTap;

  const _ChoiceTile(
      {required this.id,
      required this.label,
      required this.hint,
      required this.cost,
      required this.icon,
      required this.color,
      required this.isSelected,
      required this.isSuccess,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InteractiveButton(
      onTap: onTap,
      isSuccess: isSelected && isSuccess,
      isError: isSelected && !isSuccess,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected
                    ? color
                    : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                width: 2)),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                Text(hint,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF94A3B8))),
              ])),
          Text(cost,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              letterSpacing: 1.1)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}

class _GoalCard extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _GoalCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
