import 'package:flutter/material.dart';

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spendly',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
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
                      title: 'Practice money moves daily',
                      body:
                          'Get a virtual allowance every day and decide how to spend, save, or pay utang.',
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
                child: FilledButton(
                  onPressed: onFinished,
                  child: const Text('Get started'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Designed for Filipino youth to learn money habits through low-stress practice, not lectures.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600]),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
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
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          style:
              theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }
}

