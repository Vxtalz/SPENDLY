import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_page.dart';
import 'home_shell.dart';
import '../providers/auth_provider.dart';

import 'onboarding_page.dart';

class AuthGate extends ConsumerWidget {
  final bool seenOnboarding;
  final VoidCallback onFinishOnboarding;

  const AuthGate({
    super.key,
    required this.seenOnboarding,
    required this.onFinishOnboarding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState == AuthState.authenticated) {
      if (!seenOnboarding) {
        return OnboardingPage(onFinished: onFinishOnboarding);
      }
      return const HomeShell();
    }

    return const AuthPage();
  }
}
