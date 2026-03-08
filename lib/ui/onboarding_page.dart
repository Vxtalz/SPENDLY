import 'package:flutter/material.dart';
import 'widgets/interactive_widgets.dart';

class OnboardingPage extends StatelessWidget {
  final VoidCallback onFinished;

  const OnboardingPage({
    super.key,
    required this.onFinished,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Opacity(
                    opacity: 0,
                    child: IgnorePointer(
                      child: TextButton(
                        onPressed: null,
                        child: const Text('Skip'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Spendly',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 42,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onFinished,
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: PageView(
                  children: const [
                    _OnboardingSlide(
                      icon: Icons.flash_on,
                      title: 'Build Better Money Habits, Daily',
                      body: 'Learn it. Track it. Live it. One day at a time.',
                    ),
                    _OnboardingSlide(
                      icon: Icons.bar_chart,
                      title: 'See your patterns clearly',
                      body:
                          'Weekly and 30-day reports show how much you actually spend and save.',
                    ),
                    _OnboardingSlide(
                      icon: Icons.star_border,
                      title: 'Earn badges for good habits',
                      body:
                          'Build streaks, hit savings goals, and unlock badges as you grow your money skills.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: InteractiveButton(
                  isPrimary: true,
                  onTap: onFinished,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Get started',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Designed for Filipino youth to learn money habits through low-stress practice, not lectures.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              size: 56,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }
}
