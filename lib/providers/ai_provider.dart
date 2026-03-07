import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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

    // Check for API Key first
    if (Env.groqApiKey == 'PASTE_YOUR_GROQ_KEY_HERE' ||
        Env.groqApiKey.isEmpty) {
      _isLoading = false;
      state = [
        ...state,
        AiChatMessage(
          text:
              "Medyo may kulang pa tayo. Please go to https://console.groq.com/keys and paste your API key in env.dart!",
          isUser: false,
          timestamp: DateTime.now(),
        )
      ];
      return;
    }

    try {
      final context = await _getFinancialContext();
      final systemPrompt =
          """You are Spendly's AI Financial Assistant, a friendly and honest financial coach for Filipino youth.
Your goal is to help users manage their money better using a casual, relatable, and encouraging Taglish (Tagalog-English mix) voice.

RULES:
1. Speak in natural Taglish (e.g., 'Check natin yung budget mo,' 'Sayang naman yung streak natin.'). 
2. Use 'bes,' 'ka-Spendly,' or just be very conversational. Avoid sounding like a robot or a bank.
3. Be honest but practical. If the user is overspending, tell them 'preno-preno rin pag may time' but offer a solution.
4. Keep responses SHORT and easy to read (use bullet points if needed).
5. Always use Pesos (₱) for currency.
6. NO generic advice. Use the context provided below to give specific feedback about their balance or goals.

USER CONTEXT:
$context""";

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${Env.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": text}
          ],
          "temperature": 0.7,
          "max_tokens": 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'];

        state = [
          ...state,
          AiChatMessage(text: aiText, isUser: false, timestamp: DateTime.now())
        ];
      } else {
        throw Exception(
            "Failed to connect to Groq: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      state = [
        ...state,
        AiChatMessage(
          text: "Pasensya na, medyo may error sa pagconnect sa AI: $e",
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
