import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../env.dart';
import 'goal_provider.dart';
import 'transaction_provider.dart';
import 'simulation_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, List<AiChatMessage>>((ref) {
  return AiChatNotifier(ref);
});

class AiChatNotifier extends StateNotifier<List<AiChatMessage>> {
  final Ref _ref;

  AiChatNotifier(this._ref) : super([]);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    final userMessage =
        AiChatMessage(text: text, isUser: true, timestamp: DateTime.now());
    state = [...state, userMessage];

    _isLoading = true;
    state = [...state];

    // Get user details
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String?;
    final userName = (fullName != null && fullName.isNotEmpty) ? fullName.split(' ').first : 'ka-Spendly';

    // Check for Gemini API Key first
    if (Env.geminiApiKey == 'PASTE_YOUR_GEMINI_KEY_HERE' ||
        Env.geminiApiKey.isEmpty) {
      _isLoading = false;
      state = [
        ...state,
        AiChatMessage(
          text:
              "Wait lang, $userName! Need natin ng API key. Go to https://aistudio.google.com/app/apikey and paste your key in env.dart para makapag-usap tayo!",
          isUser: false,
          timestamp: DateTime.now(),
        )
      ];
      return;
    }

    try {
      final context = await _getFinancialContext();
      
      final chatContext = state
          .where((m) => !m.text.startsWith('Wait lang') && !m.text.startsWith('Pasensya na') && !m.text.startsWith('Medyo may system'))
          .map((m) => "${m.isUser ? 'User' : 'AI'}: ${m.text}")
          .join('\n');

      final systemPrompt =
          """You are Spendly's AI Financial Assistant, a friendly and honest financial coach for Filipino youth. Speak in natural Taglish (Tagalog-English mix) voice. Always address the user by their name '$userName' (e.g., "Hi $userName, how can I help you?") instead of 'bes' or 'ka-Spendly'. Be short, friendly, and use Pesos (₱).""";

      try {
        final recordTransactionTool = Tool(functionDeclarations: [
          FunctionDeclaration(
            'record_transaction',
            'Record a financial transaction when the user explicitly says they spent, bought, saved, or received money.',
            Schema(
              SchemaType.object,
              properties: {
                'type': Schema(SchemaType.string, description: 'Must be "income", "expense", or "save"'),
                'amount': Schema(SchemaType.number, description: 'The absolute amount in Pesos. DO NOT miss zeros! (e.g. if user says 50k, log 50000. "1k" = 1000)'),
                'category': Schema(SchemaType.string, description: 'Category name (e.g. "Pizza", "Salary")'),
              },
              requiredProperties: ['type', 'amount', 'category'],
            ),
          )
        ]);

        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: Env.geminiApiKey,
          tools: [recordTransactionTool],
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 800,
          ),
          systemInstruction: Content.system("$systemPrompt\n\nUSER CONTEXT:\n$context\n\nCONVERSATION HISTORY:\n$chatContext"),
        );

        final contents = [Content.text(text)];
        var response = await model.generateContent(contents);

        if (response.functionCalls.isNotEmpty) {
          final call = response.functionCalls.first;
          if (call.name == 'record_transaction') {
            final args = call.args;
            final String type = args['type'] as String? ?? 'expense';
            final double amount = (args['amount'] as num?)?.toDouble() ?? 0.0;
            final String category = args['category'] as String? ?? 'AI Recorded';

            if (amount > 0) {
              final txNotifier = _ref.read(transactionListProvider.notifier);
              final simNotifier = _ref.read(simulationProvider.notifier);

              final pesos = amount.toInt();
              final amountCents = type == 'expense' ? -(pesos * 100) : (pesos * 100);

              if (type == 'expense') {
                await simNotifier.logExpense(pesos.toDouble());
              } else if (type == 'save') {
                await simNotifier.logSaving(pesos.toDouble());
              } else {
                final curr = _ref.read(simulationProvider);
                await simNotifier.updateState(curr.copyWith(balance: curr.balance + pesos));
              }

              await txNotifier.add(
                amountCents: amountCents,
                category: category,
                type: type,
              );

              contents.add(response.candidates.first.content);
              contents.add(Content.functionResponse('record_transaction', {
                'status': 'success',
                'details': 'Recorded $type of $pesos for $category'
              }));
              
              response = await model.generateContent(contents);
            }
          }
        }

        if (response.text != null && response.text!.isNotEmpty) {
          state = [
            ...state,
            AiChatMessage(
                text: response.text!, isUser: false, timestamp: DateTime.now())
          ];
        } else {
          throw Exception("No content in response");
        }
      } on GenerativeAIException catch (e) {
        state = [
          ...state,
          AiChatMessage(
            text:
                "Pasensya na, $userName! May inayos lang akong konti (Err: API Issue). Double check mo yung API key mo baka nagkalat lang, ha? Balikan kita agad! Detalles: $e",
            isUser: false,
            timestamp: DateTime.now(),
          )
        ];
      }
    } catch (e) {
      state = [
        ...state,
        AiChatMessage(
          text:
              "Medyo may system issue tayo, $userName. Balikan kita maya-maya! 😅 (Error: $e)",
          isUser: false,
          timestamp: DateTime.now(),
        )
      ];
    } finally {
      _isLoading = false;
      state = [...state];
    }
  }

  void clearChat() {
    state = [];
  }

  Future<String> _getFinancialContext() async {
    final goal = _ref.read(goalProvider);
    final transactions = _ref.read(transactionListProvider);
    final simState = _ref.read(simulationProvider);
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return "No user logged in.";

    final buffer = StringBuffer();

    if (goal != null) {
      buffer.writeln(
          "Goal: ${goal.period.name} limit (₱${goal.amountCents / 100})");
    }

    buffer.writeln("Balance: ₱${simState.balance}");
    buffer.writeln("Savings: ₱${simState.savings}");
    buffer.writeln("Debt: ₱${simState.debt}");
    buffer.writeln("Streak: ${simState.streakDays} days");

    final recentTxs = transactions.take(5).toList();
    if (recentTxs.isNotEmpty) {
      buffer.writeln("Last 5 txs:");
      for (var tx in recentTxs) {
        buffer.writeln("- ${tx.category}: ₱${tx.amountCents / 100}");
      }
    }

    return buffer.toString();
  }
}
