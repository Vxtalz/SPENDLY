import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/scenario_provider.dart';

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
            const Color(0xFFFF4B4B),
          ];
          final List<Color> shadowColors = [
            const Color(0xFF5348B2),
            const Color(0xFF98CA28),
            const Color(0xFF00A3C7),
            const Color(0xFFD38B9C),
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
                        color: shadowColor,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_stories,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: TextStyle(
                                color: isLime
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              p.topic,
                              style: TextStyle(
                                color: isLime
                                    ? const Color(0xFF1A1A1A)
                                        .withValues(alpha: 0.7)
                                    : Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                            width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            m.completed
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: m.completed
                                ? const Color(0xFF58CC02)
                                : const Color(0xFFE5E5E5),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: m.completed
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF1A1A1A),
                                    decoration: m.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if (!m.completed)
                                  Text(
                                    m.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFAFAFAF),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!m.completed)
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  await ref
                                      .read(scenarioPacksProvider.notifier)
                                      .markModuleCompleted(m.id);
                                  messenger.showSnackBar(SnackBar(
                                      content: Text('Completed: ${m.title}')));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('START',
                                    style: TextStyle(
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
}
