import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthState {
  unauthenticated,
  authenticating,
  authenticated,
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.unauthenticated);

  final _client = Supabase.instance.client;

  Future<void> signUp(String email, String password) async {
    state = AuthState.authenticating;
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      // If the backend is configured to auto-confirm, a session may already be present.
      if (_client.auth.currentSession != null || res.session != null) {
        state = AuthState.authenticated;
        return;
      }
      // Otherwise, attempt immediate sign-in (will fail if email confirmation is enforced).
      await _client.auth.signInWithPassword(email: email, password: password);
      state = AuthState.authenticated;
    } on AuthException {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    state = AuthState.authenticating;
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      state = AuthState.authenticated;
    } on AuthException {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
