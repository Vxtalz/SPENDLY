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

    // Check for Gemini API Key first
    if (Env.geminiApiKey == 'PASTE_YOUR_GEMINI_KEY_HERE' ||
        Env.geminiApiKey.isEmpty) {
      _isLoading = false;
      state = [
        ...state,
        AiChatMessage(
          text:
              "Wait lang, bes! Need natin ng API key. Go to https://aistudio.google.com/app/apikey and paste your key in env.dart para makapag-usap tayo!",
          isUser: false,
          timestamp: DateTime.now(),
        )
      ];
      return;
    }

    try {
      final context = await _getFinancialContext();
      final systemPrompt =
          """You are Spendly's AI Financial Assistant, a friendly and honest financial coach for Filipino youth. Speak in natural Taglish (Tagalog-English mix) voice. Use 'bes' or 'ka-Spendly'. Be short and use Pesos (₱).
          
USER CONTEXT:
$context""";

      // Using Gemini 2.5 Flash (The 2026 Standard)
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${Env.geminiApiKey}');

      Future<http.Response> makeRequest() => http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": "$systemPrompt\n\nUSER QUESTION: $text"}
                  ]
                }
              ],
              "generationConfig": {
                "temperature": 0.7,
                "maxOutputTokens": 800,
              }
            }),
          );

      var response = await makeRequest();

      // If Rate Limited (429), wait 2 seconds and retry once
      if (response.statusCode == 429) {
        await Future.delayed(const Duration(seconds: 2));
        response = await makeRequest();
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final aiText = data['candidates'][0]['content']['parts'][0]['text'];
          state = [
            ...state,
            AiChatMessage(
                text: aiText, isUser: false, timestamp: DateTime.now())
          ];
        } else {
          throw Exception("No content in response");
        }
      } else {
        // Fallback with specific error code
        state = [
          ...state,
          AiChatMessage(
            text:
                "Pasensya na, bes! Medyo busy ang line sa AI side (Err: ${response.statusCode}). Check mo muna yung savings mo, ha? Balikan kita agad!",
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
              "Medyo may system issue tayo, bes. Balikan kita maya-maya! 😅 (Error: $e)",
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
