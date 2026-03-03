import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/scenario_provider.dart';

class ScenariosPage extends ConsumerWidget {
  const ScenariosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(scenarioPacksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scenario Packs')),
      body: ListView.builder(
        itemCount: packs.length,
        itemBuilder: (context, i) {
          final p = packs[i];
          return ExpansionTile(
            title: Text(p.title),
            subtitle: Text(p.topic),
            children: [
              for (final m in p.modules)
                ListTile(
                  title: Text(m.title),
                  subtitle: Text(m.description),
                  trailing: m.completed
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : FilledButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await ref.read(scenarioPacksProvider.notifier).markModuleCompleted(m.id);
                            messenger.showSnackBar(
                                SnackBar(content: Text('Completed: ${m.title}')));
                          },
                          child: const Text('Complete'),
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}
