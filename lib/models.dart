import 'dart:convert';

/// Goal to Spend
enum GoalPeriod { daily, weekly }

class SpendGoal {
  final GoalPeriod period;
  final int amountCents; // store in centavos to avoid FP issues
  final DateTime startAt;
  final DateTime? endAt; // optional explicit end
  final bool completed; // whether period concluded
  final int spentCents; // tracked spending during the period

  const SpendGoal({
    required this.period,
    required this.amountCents,
    required this.startAt,
    this.endAt,
    this.completed = false,
    this.spentCents = 0,
  });

  SpendGoal copyWith({
    GoalPeriod? period,
    int? amountCents,
    DateTime? startAt,
    DateTime? endAt,
    bool? completed,
    int? spentCents,
  }) {
    return SpendGoal(
      period: period ?? this.period,
      amountCents: amountCents ?? this.amountCents,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      completed: completed ?? this.completed,
      spentCents: spentCents ?? this.spentCents,
    );
  }

  bool get isActive => !completed && DateTime.now().isBefore(periodEnd);

  DateTime get periodEnd {
    if (endAt != null) return endAt!;
    switch (period) {
      case GoalPeriod.daily:
        return DateTime(startAt.year, startAt.month, startAt.day)
            .add(const Duration(days: 1));
      case GoalPeriod.weekly:
        return DateTime(startAt.year, startAt.month, startAt.day)
            .add(const Duration(days: 7));
    }
  }

  double get progress =>
      amountCents == 0 ? 0 : (spentCents / amountCents).clamp(0, 1);
  bool get hit => spentCents <= amountCents;

  Map<String, dynamic> toJson() => {
        'period': period.name,
        'amountCents': amountCents,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
        'completed': completed,
        'spentCents': spentCents,
      };

  factory SpendGoal.fromJson(Map<String, dynamic> json) => SpendGoal(
        period: GoalPeriod.values.firstWhere((e) => e.name == json['period']),
        amountCents: json['amountCents'] as int,
        startAt: DateTime.parse(json['startAt'] as String),
        endAt: json['endAt'] != null
            ? DateTime.parse(json['endAt'] as String)
            : null,
        completed: json['completed'] as bool? ?? false,
        spentCents: json['spentCents'] as int? ?? 0,
      );
}

/// Simulation State
class SimulationState {
  final double balance;
  final double savings;
  final double debt;
  final int currentDay;
  final int cycleNumber;
  final int streakDays;
  final DateTime? lastPlayedDate;
  final String? todayGoal;
  final String? todayType;
  final double todayAllowance;

  const SimulationState({
    this.balance = 0.0,
    this.savings = 0.0,
    this.debt = 0.0,
    this.currentDay = 1,
    this.cycleNumber = 1,
    this.streakDays = 0,
    this.lastPlayedDate,
    this.todayGoal,
    this.todayType,
    this.todayAllowance = 0.0,
  });

  SimulationState copyWith({
    double? balance,
    double? savings,
    double? debt,
    int? currentDay,
    int? cycleNumber,
    int? streakDays,
    DateTime? lastPlayedDate,
    String? todayGoal,
    String? todayType,
    double? todayAllowance,
  }) {
    return SimulationState(
      balance: balance ?? this.balance,
      savings: savings ?? this.savings,
      debt: debt ?? this.debt,
      currentDay: currentDay ?? this.currentDay,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      streakDays: streakDays ?? this.streakDays,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      todayGoal: todayGoal ?? this.todayGoal,
      todayType: todayType ?? this.todayType,
      todayAllowance: todayAllowance ?? this.todayAllowance,
    );
  }

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'savings': savings,
        'debt': debt,
        'current_day': currentDay,
        'cycle_number': cycleNumber,
        'streak_days': streakDays,
        'last_played_date': lastPlayedDate?.toIso8601String().substring(0, 10),
        'today_goal': todayGoal,
        'today_type': todayType,
        'today_allowance': todayAllowance,
      };

  factory SimulationState.fromJson(Map<String, dynamic> json) =>
      SimulationState(
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
        savings: (json['savings'] as num?)?.toDouble() ?? 0.0,
        debt: (json['debt'] as num?)?.toDouble() ?? 0.0,
        currentDay: json['current_day'] as int? ?? 1,
        cycleNumber: json['cycle_number'] as int? ?? 1,
        streakDays: json['streak_days'] as int? ?? 0,
        lastPlayedDate: json['last_played_date'] != null
            ? DateTime.parse(json['last_played_date'] as String)
            : null,
        todayGoal: json['today_goal'] as String?,
        todayType: json['today_type'] as String?,
        todayAllowance: (json['today_allowance'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Real Transaction Tracker
class TransactionEntry {
  final String id;
  final int amountCents;
  final String category; // e.g., Food, Transport, Bills
  final DateTime timestamp;
  final String? note;
  final String? receiptId; // link to ReceiptEntry

  const TransactionEntry({
    required this.id,
    required this.amountCents,
    required this.category,
    required this.timestamp,
    this.note,
    this.receiptId,
  });

  TransactionEntry copyWith({
    String? id,
    int? amountCents,
    String? category,
    DateTime? timestamp,
    String? note,
    String? receiptId,
  }) {
    return TransactionEntry(
      id: id ?? this.id,
      amountCents: amountCents ?? this.amountCents,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      receiptId: receiptId ?? this.receiptId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amountCents': amountCents,
        'category': category,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
        'receiptId': receiptId,
      };

  factory TransactionEntry.fromJson(Map<String, dynamic> json) =>
      TransactionEntry(
        id: json['id'] as String,
        amountCents: json['amountCents'] as int,
        category: json['category'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        note: json['note'] as String?,
        receiptId: json['receiptId'] as String?,
      );
}

/// Resibo — Receipt Logger
class ReceiptEntry {
  final String id;
  final String? imagePath; // local path or network URL
  final String merchant;
  final int totalCents;
  final DateTime timestamp;
  final String? note;

  const ReceiptEntry({
    required this.id,
    required this.merchant,
    required this.totalCents,
    required this.timestamp,
    this.imagePath,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'merchant': merchant,
        'totalCents': totalCents,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory ReceiptEntry.fromJson(Map<String, dynamic> json) => ReceiptEntry(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String?,
        merchant: json['merchant'] as String,
        totalCents: json['totalCents'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        note: json['note'] as String?,
      );
}

/// Preloaded Scenario Packs and modules
class ScenarioModule {
  final String id;
  final String title;
  final String description;
  final bool completed;

  const ScenarioModule({
    required this.id,
    required this.title,
    required this.description,
    this.completed = false,
  });

  ScenarioModule copyWith({bool? completed}) => ScenarioModule(
        id: id,
        title: title,
        description: description,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'completed': completed,
      };

  factory ScenarioModule.fromJson(Map<String, dynamic> json) => ScenarioModule(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        completed: json['completed'] as bool? ?? false,
      );
}

class ScenarioPack {
  final String id;
  final String title;
  final String topic; // e.g., Savings Basics
  final List<ScenarioModule> modules;

  const ScenarioPack({
    required this.id,
    required this.title,
    required this.topic,
    required this.modules,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'topic': topic,
        'modules': modules.map((m) => m.toJson()).toList(),
      };

  factory ScenarioPack.fromJson(Map<String, dynamic> json) => ScenarioPack(
        id: json['id'] as String,
        title: json['title'] as String,
        topic: json['topic'] as String,
        modules: (json['modules'] as List<dynamic>)
            .map((e) => ScenarioModule.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Entitlement / Premium state
class EntitlementState {
  final DateTime trialStartedAt;
  final bool premium; // user purchased subscription

  const EntitlementState({
    required this.trialStartedAt,
    required this.premium,
  });

  bool get isTrialActive =>
      DateTime.now().difference(trialStartedAt).inDays < 30;
  int get trialDaysRemaining =>
      (30 - DateTime.now().difference(trialStartedAt).inDays).clamp(0, 30);
  bool get isPremium => premium || isTrialActive;

  Map<String, dynamic> toJson() => {
        'trialStartedAt': trialStartedAt.toIso8601String(),
        'premium': premium,
      };

  factory EntitlementState.fromJson(Map<String, dynamic> json) =>
      EntitlementState(
        trialStartedAt: DateTime.parse(json['trialStartedAt'] as String),
        premium: json['premium'] as bool? ?? false,
      );
}

/// Partner Offers (simple representation)
enum PartnerType { bank, insurance }

class PartnerOffer {
  final String id;
  final PartnerType type;
  final String name;
  final String ctaUrl; // external link
  final String triggerModuleId; // module completion trigger

  const PartnerOffer({
    required this.id,
    required this.type,
    required this.name,
    required this.ctaUrl,
    required this.triggerModuleId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'ctaUrl': ctaUrl,
        'triggerModuleId': triggerModuleId,
      };

  factory PartnerOffer.fromJson(Map<String, dynamic> json) => PartnerOffer(
        id: json['id'] as String,
        type: PartnerType.values.firstWhere((e) => e.name == json['type']),
        name: json['name'] as String,
        ctaUrl: json['ctaUrl'] as String,
        triggerModuleId: json['triggerModuleId'] as String,
      );
}

/// Simple helpers
String encodeList(List<Map<String, dynamic>> list) => jsonEncode(list);
List<Map<String, dynamic>> decodeList(String? src) => src == null || src.isEmpty
    ? <Map<String, dynamic>>[]
    : List<Map<String, dynamic>>.from(jsonDecode(src) as List);
