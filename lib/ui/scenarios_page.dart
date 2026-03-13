import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../models.dart';
import '../providers/scenario_provider.dart';
import 'widgets/interactive_widgets.dart';

class ScenariosPage extends ConsumerWidget {
  const ScenariosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(scenarioPacksProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('SCENARIO PACKS'),
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              height: 1),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: packs.length,
        itemBuilder: (context, i) {
          final p = packs[i];
          final packIndex = i;

          final List<Color> colors = [
            const Color(0xFF6A5AE0),
            const Color(0xFFC0FF00),
            const Color(0xFF00D1FF),
            const Color(0xFFFF4B4B)
          ];
          final List<Color> shadowColors = [
            const Color(0xFF5348B2),
            const Color(0xFF98CA28),
            const Color(0xFF00A3C7),
            const Color(0xFFD38B9C)
          ];

          final color = colors[packIndex % colors.length];
          final shadowColor = shadowColors[packIndex % shadowColors.length];
          final isLime = color == const Color(0xFFC0FF00);

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: shadowColor, offset: const Offset(0, 4))
                      ]),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_stories,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title,
                                style: TextStyle(
                                    color: isLime
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text(p.topic,
                                style: TextStyle(
                                    color: isLime
                                        ? const Color(0xFF1A1A1A)
                                            .withValues(alpha: 0.7)
                                        : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...p.modules.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.1),
                              width: 2)),
                      child: Row(
                        children: [
                          Icon(
                              m.completed
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: m.completed
                                  ? const Color(0xFF58CC02)
                                  : const Color(0xFFE5E5E5)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.title,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: m.completed
                                            ? const Color(0xFF94A3B8)
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                        decoration: m.completed
                                            ? TextDecoration.lineThrough
                                            : null)),
                                if (!m.completed)
                                  Text(m.description,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                          if (!m.completed)
                            InteractiveButton(
                              isPrimary: true,
                              onTap: () async {
                                final gamifiedPrefixes = [
                                  'debt_',
                                  'save_',
                                  'scam_',
                                  'insurance_',
                                  'invest_',
                                  'salary_'
                                ];
                                bool isGamified = gamifiedPrefixes
                                    .any((pre) => m.id.startsWith(pre));

                                if (isGamified) {
                                  _showInteractiveScenario(context, ref, m);
                                } else {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  await ref
                                      .read(scenarioPacksProvider.notifier)
                                      .markModuleCompleted(m.id);
                                  messenger.showSnackBar(SnackBar(
                                      content: Text('Completed: ${m.title}')));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Text('START',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInteractiveScenario(
      BuildContext context, WidgetRef ref, ScenarioModule m) {
    String story = "";
    String choice1 = "";
    String result1 = "";
    String choice2 = "";
    String result2 = "";
    String emoji = "📱";

    // DEBT TRAP
    if (m.id == 'debt_temptation') {
      story =
          "The new 'SuperPhone X' just launched. It's sleek, fast, and everyone in your group chat is getting one. You have ₱5,000, but the phone is ₱35,000.";
      choice1 = "12-Month Installment (₱3,500/mo)";
      result1 =
          "You got the phone! But wait... ₱3,500 x 12 = ₱42,000. You just paid ₱7,000 in interest. That's the Debt Monster taking a bite!";
      choice2 = "Wait and Save (Stock phone for now)";
      result2 =
          "Disciplined! Your ₱5,000 remains yours, and you avoided a ₱7,000 interest trap. You're building a 'Fort' of wealth!";
      emoji = "📲";
    } else if (m.id == 'debt_monster') {
      story =
          "A flyer says '0% interest for 6 months!' It sounds perfect for that new laptop you need. But the fine print is tiny.";
      choice1 = "Sign up immediately!";
      result1 =
          "Oh no! You missed one payment by 1 day, and they charged you back-interest for the whole 6 months. The Debt Monster has evolved!";
      choice2 = "Read the fine print first";
      result2 =
          "Sharp eye! You noticed the ₱1,000 'processing fee' and high penalties. You decided to wait for a real sale instead.";
      emoji = "🐉";
    } else if (m.id == 'debt_escape') {
      story =
          "You have ₱10,000 extra this month. Your debt balance is ₱20,000 (20% interest). But there's also a cool 'Limited Edition' sneakers drop for ₱8,000.";
      choice1 = "Buy the Sneakers (Deserve ko 'to!)";
      result1 =
          "Style points +10, but your debt grew by ₱400 in interest this month. The spiral continues...";
      choice2 = "Pay off half the debt";
      result2 =
          "Awesome! You just saved yourself ₱2,000 in future interest. You're breaking the cycle!";
      emoji = "🏃";
    }
    // SAVINGS FORT
    else if (m.id == 'save_storm') {
      story =
          "Thunder rumbles! Your phone screen suddenly flickers and dies. The repair shop says it will cost ₱3,000. Do you have a fort?";
      choice1 = "Use your 'Fort' (Emergency Fund)";
      result1 =
          "The fort held! You paid ₱3,000 without stressing about next week's meals. That's why we build walls!";
      choice2 = "Borrow from a friend";
      result2 =
          "You're safe for today, but now you owe a debt. Your fort is empty and you're exposed to the next storm!";
      emoji = "⛈️";
    } else if (m.id == 'save_first') {
      story =
          "Payday! ₱15,000 just hit your account. Your 'To-Buy' list is long, but your Savings Fort is looking thin.";
      choice1 = "Buy the upgrades first";
      result1 =
          "You look great, but after bills, you have ₱0 left for your fort. One 'Storm' and you're in trouble!";
      choice2 = "Move ₱3,000 to Fort immediately";
      result2 =
          "Brilliant! You 'Paid Yourself First'. The remaining ₱12,000 is for bills and fun. The fort grows!";
      emoji = "🏰";
    }
    // SCAM WARS
    else if (m.id == 'scam_phish') {
      story =
          "TEXT: 'GCASH ALERT! Your account will be BLOCKED. Click here to verify: bit.ly/g-cash-secure-123'. What do you do?";
      choice1 = "Click and Login to 'Verify'";
      result1 =
          "NO! That was a fishing site. They just stole your credentials. The SMS Wars are brutal—be careful!";
      choice2 = "Ignore and report as Spam";
      result2 =
          "VICTORY! You spotted the 'Red Flags' (urgent tone, weird link). Your assets are safe, Scambuster!";
      emoji = "🕵️";
    }
    // INSURANCE NET
    else if (m.id == 'insurance_tightrope' || m.id == 'insurance_horror') {
      story =
          "You're walking the tightrope of life. Suddenly, a medical emergency 'Anvil' falls! Hospital bills: ₱50,000.";
      choice1 = "I have no Insurance Net";
      result1 =
          "The fall is hard. ₱50,000 gone from your savings in one day. Your progress is reset to zero.";
      choice2 = "Deploy Health Insurance Net";
      result2 =
          "BOUNCY! The insurance net caught the ₱50,000 bill. You walk away with only a ₱2,000 processing fee. Safe!";
      emoji = "🪂";
    } else if (m.id == 'insurance_peace') {
      story =
          "You pay ₱500/month for your 'Net'. It feels like a waste... until a minor accident happens.";
      choice1 = "Cancel the Net to save ₱500";
      result1 =
          "You saved ₱500, but you lost your peace of mind. Every sneeze now feels like a financial threat!";
      choice2 = "Keep the Peace of Mind";
      result2 =
          "Wise move. You're not just buying a net; you're buying the ability to walk the tightrope without fear.";
      emoji = "🛡️";
    }
    // INVESTMENT SPEED
    else if (m.id == 'invest_race') {
      story =
          "You're in the Risk vs Return Race. Option A: A safe 'Turtle' (2% return). Option B: A wild 'Jaguar' (25% return).";
      choice1 = "Go 100% Jaguar!";
      result1 =
          "FAST! But the Jaguar tripped on a market crash 'Obstacle'. You lost 40% of your speed. High risk, high pain!";
      choice2 = "Balance Turtle and Jaguar";
      result2 =
          "PRO! You used 'Diversification'. The Jaguar took a hit, but the Turtle kept you moving forward. Dynamic balance!";
      emoji = "🏎️";
    }
    // SALARY SURVIVAL
    else if (m.id == 'salary_libre') {
      story =
          "Payday! Your cousins and friends are chanting: 'LIBRE! LIBRE! LIBRE!' (Treat us!). Your budget only allows for ₱500 fun money.";
      choice1 = "Treat everyone (₱3,000)";
      result1 =
          "You're the hero for one night, but you're eating instant noodles for the next two weeks. Survival: FAILED.";
      choice2 = "Declined with a smile (₱0)";
      result2 =
          "It was awkward for 5 seconds, but your budget survived. You offer to host a 'Home Movie Night' instead. Survival: HERO!";
      emoji = "🍖";
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Scenario',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return _ScenarioDialogContent(
          m: m,
          story: story,
          choice1: choice1,
          result1: result1,
          choice2: choice2,
          result2: result2,
          emoji: emoji,
          ref: ref,
        );
      },
    );
  }
}

class _ScenarioDialogContent extends StatefulWidget {
  final ScenarioModule m;
  final String story;
  final String choice1;
  final String result1;
  final String choice2;
  final String result2;
  final String emoji;
  final WidgetRef ref;

  const _ScenarioDialogContent({
    required this.m,
    required this.story,
    required this.choice1,
    required this.result1,
    required this.choice2,
    required this.result2,
    required this.emoji,
    required this.ref,
  });

  @override
  State<_ScenarioDialogContent> createState() => _ScenarioDialogContentState();
}

class _ScenarioDialogContentState extends State<_ScenarioDialogContent>
    with TickerProviderStateMixin {
  bool chosen = false;
  String feedback = "";
  bool isGood = false;

  late AnimationController _timerController;
  late AnimationController _shakeController;

  String showedStory = "";
  bool _isTyping = true;

  // Interaction State
  double sliderValue = 0.5;
  int currentTaps = 0;
  final int totalTaps = 3;
  Offset tapPos = const Offset(0.5, 0.4);

  // New Game State
  String characterMood = "😐"; // 😐, 😃, 😱, 😈, 🤑
  Color moodColor = const Color(0xFF151515);
  static int currentStreak = 0; // Track across modules in this session

  @override
  void initState() {
    super.initState();
    _timerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12));
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _startTypewriter();
    _updateMood();
    _timerController.forward().then((_) {
      if (mounted && !chosen) _handleChoice(isChoice1: true);
    });
  }

  void _moveTapTarget() {
    setState(() {
      tapPos = Offset(0.2 + math.Random().nextDouble() * 0.6,
          0.3 + math.Random().nextDouble() * 0.4);
    });
  }

  void _updateMood() {
    characterMood = widget.emoji;
    if (widget.m.id.startsWith('debt_')) characterMood = "😈";
    if (widget.m.id.startsWith('save_')) characterMood = "🏦";
    if (widget.m.id.startsWith('invest_')) characterMood = "📈";
    if (widget.m.id.startsWith('salary_')) characterMood = "👔";

    // Specific override for Phishing - Using light skin detective
    if (widget.m.id == 'scam_phish') characterMood = "🕵🏻";
  }

  void _startTypewriter() async {
    for (int i = 0; i <= widget.story.length; i++) {
      if (!mounted) return;
      setState(() {
        showedStory = widget.story.substring(0, i);
      });
      await Future.delayed(const Duration(milliseconds: 10));
    }
    setState(() {
      _isTyping = false;
    });
  }

  void _handleChoice({required bool isChoice1}) {
    if (chosen) return;
    _timerController.stop();

    setState(() {
      chosen = true;
      feedback = isChoice1 ? widget.result1 : widget.result2;
      isGood = !isChoice1;

      // Update mood and streak based on outcome
      if (isGood) {
        currentStreak++;
        characterMood = "✨";
        moodColor = const Color(0xFFC0FF00).withValues(alpha: 0.15);
      } else {
        currentStreak = 0;
        characterMood = "💀";
        moodColor = Colors.red.withValues(alpha: 0.15);
        _shakeController.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isScam = widget.m.id.startsWith('scam_');
    final bool isInvest = widget.m.id.startsWith('invest_');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // FULL SCREEN MOOD OVERLAY
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            color: chosen ? moodColor : Colors.black.withValues(alpha: 0.95),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                double shake =
                    math.sin(_shakeController.value * math.pi * 10) * 12;
                return Transform.translate(
                  offset: Offset(shake, 0),
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // CHARACTER BOX
                    _CharacterAvatar(mood: characterMood),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: chosen
                              ? (isGood
                                  ? const Color(0xFFC0FF00)
                                  : Colors.redAccent)
                              : Colors.white10,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _StatHUD(
                                  icon: '🏦', label: 'Vault', active: true),
                              if (currentStreak > 0)
                                _StatHUD(
                                    icon: '🔥',
                                    label: 'Streak: $currentStreak',
                                    color: Colors.orange,
                                    active: true),
                              _StatHUD(
                                  icon: '⚡',
                                  label: 'Willpower',
                                  color: const Color(0xFF00D1FF),
                                  active: !chosen),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _DialogueDisplay(
                              text: chosen ? feedback : showedStory,
                              isOutcome: chosen,
                              isGood: isGood),
                          const SizedBox(height: 32),
                          if (!chosen) ...[
                            // PROGRESS TIMER (Universal)
                            _GameTimer(controller: _timerController),
                            const SizedBox(height: 24),

                            if (isScam)
                              const Text("TAP THE SHIELD TO BLOCK!",
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 1))
                            else if (isInvest)
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("CONSERVATIVE",
                                          style: TextStyle(
                                              color: Colors.white30,
                                              fontSize: 9)),
                                      Text(
                                          "ALLOCATION: ${(sliderValue * 100).toInt()}%",
                                          style: const TextStyle(
                                              color: Color(0xFFC0FF00),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11)),
                                      const Text("AGGRESSIVE",
                                          style: TextStyle(
                                              color: Colors.white30,
                                              fontSize: 9)),
                                    ],
                                  ),
                                  Slider(
                                    value: sliderValue,
                                    activeColor: const Color(0xFFC0FF00),
                                    inactiveColor: Colors.white10,
                                    onChanged: (v) =>
                                        setState(() => sliderValue = v),
                                  ),
                                  _GameButton(
                                      label: "EXECUTE TRADE",
                                      onTap: () => _handleChoice(
                                          isChoice1: sliderValue > 0.8),
                                      isSecondary: false),
                                ],
                              )
                            else ...[
                              _GameButton(
                                  label: widget.choice1,
                                  onTap: _isTyping
                                      ? null
                                      : () => _handleChoice(isChoice1: true),
                                  isSecondary: true),
                              const SizedBox(height: 12),
                              _GameButton(
                                  label: widget.choice2,
                                  onTap: _isTyping
                                      ? null
                                      : () => _handleChoice(isChoice1: false),
                                  isSecondary: false),
                            ]
                          ] else ...[
                            _GameButton(
                              label:
                                  isGood ? "LEVEL UP!" : "TRY AGAIN NEXT TIME",
                              onTap: () async {
                                await widget.ref
                                    .read(scenarioPacksProvider.notifier)
                                    .markModuleCompleted(widget.m.id);
                                if (context.mounted) Navigator.pop(context);
                              },
                              isSecondary: false,
                              color: isGood
                                  ? const Color(0xFFC0FF00)
                                  : Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // MINI-GAME OVERLAY (FOR SCAMS) - MOVED TO TOP OF STACK
          if (isScam && !chosen && !_isTyping)
            Positioned(
              left: MediaQuery.of(context).size.width * tapPos.dx - 40,
              top: MediaQuery.of(context).size.height * tapPos.dy - 40,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() => currentTaps++);
                    if (currentTaps >= totalTaps) {
                      _handleChoice(isChoice1: false);
                    } else {
                      _moveTapTarget();
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC0FF00).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFC0FF00), width: 3),
                      boxShadow: [
                        BoxShadow(
                            color:
                                const Color(0xFFC0FF00).withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5)
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield,
                              color: Color(0xFFC0FF00), size: 32),
                          Text("${totalTaps - currentTaps}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DialogueDisplay extends StatelessWidget {
  final String text;
  final bool isOutcome;
  final bool isGood;
  const _DialogueDisplay(
      {required this.text, required this.isOutcome, required this.isGood});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                      fontStyle:
                          isOutcome ? FontStyle.italic : FontStyle.normal)),
              if (isOutcome) ...[
                const SizedBox(height: 12),
                Text(isGood ? "MISSION ACCOMPLISHED" : "MISSION FAILED",
                    style: TextStyle(
                        color:
                            isGood ? const Color(0xFFC0FF00) : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12))
              ]
            ],
          ),
        ),
        Positioned(
            top: -10,
            left: 20,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(isOutcome ? "RESULT" : "PHASE",
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)))),
      ],
    );
  }
}

class _GameTimer extends StatelessWidget {
  final AnimationController controller;
  const _GameTimer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("STABILITY",
                    style: TextStyle(
                        color: Colors.white24,
                        fontSize: 8,
                        fontWeight: FontWeight.bold)),
                Text("${((1.0 - controller.value) * 12).toInt()}s",
                    style: TextStyle(
                        color: controller.value > 0.8
                            ? Colors.red
                            : Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 1.0 - controller.value,
                minHeight: 6,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(controller.value > 0.8
                    ? Colors.red
                    : const Color(0xFFC0FF00)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CharacterAvatar extends StatelessWidget {
  final String mood;
  const _CharacterAvatar({required this.mood});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9), // High contrast background
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFC0FF00), width: 3),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFC0FF00).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2)
        ],
      ),
      child: Text(mood, style: const TextStyle(fontSize: 48)),
    );
  }
}

class _GameButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isSecondary;
  final Color? color;

  const _GameButton({
    required this.label,
    required this.onTap,
    required this.isSecondary,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveButton(
      isPrimary: true,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ??
              (isSecondary
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFC0FF00)),
          borderRadius: BorderRadius.circular(20),
          border: isSecondary ? Border.all(color: Colors.white10) : null,
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
              color: isSecondary ||
                      (color != null && color != const Color(0xFFC0FF00))
                  ? Colors.white
                  : Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2),
        ),
      ),
    );
  }
}

class _StatHUD extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final bool active;

  const _StatHUD({
    required this.icon,
    required this.label,
    this.color = const Color(0xFFC0FF00),
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? color : Colors.white10, width: active ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(icon),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: active ? Colors.white : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
