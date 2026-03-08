import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/entitlement_provider.dart';
import 'widgets/interactive_widgets.dart';

class PremiumPage extends ConsumerWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ent = ref.watch(entitlementProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Premium (₱99/month)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ent != null && ent.isTrialActive)
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.rocket_launch_outlined,
                      color: Colors.green),
                  title: Text(
                      'Free Trial Active — ${ent.trialDaysRemaining} days left'),
                  subtitle: const Text(
                      'All features are unlocked during the 30-day trial.'),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: const Icon(Icons.lock_open_rounded),
                    title: const Text('Subscribe to Premium'),
                    subtitle:
                        const Text('₱99 per month after your free trial.'),
                    trailing: InteractiveButton(
                      isPrimary: true,
                      onTap: () => ref
                          .read(entitlementProvider.notifier)
                          .setPremium(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC0FF00),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Activate',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text('What ₱99 gets you',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars_rounded,
                      color: theme.colorScheme.secondary, size: 40),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Ready to level up? Unlocking premium gives you the full Spendly experience!",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _Bullet('All preloaded scenario packs'),
            const _Bullet('Real transaction tracker'),
            const _Bullet('Resibo receipt logger'),
            const _Bullet('Goal to spend feature'),
            const _Bullet('Full weekly and monthly reports'),
            const _Bullet('Ad free experience'),
            const _Bullet('Partner bank and insurance access'),
            const _Bullet('Exclusive leaderboard rewards'),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('• '),
        Expanded(child: Text(text)),
      ]),
    );
  }
}
