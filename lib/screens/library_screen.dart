import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/session/session_controller.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final List<TestDefinition> registry;
  const LibraryScreen({super.key, required this.registry});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final Set<String> selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final plan = widget.registry
        .where((t) => selectedIds.contains(t.id))
        .map((t) => t.id)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Choose tests')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Selected plan'),
            subtitle: Text(plan.isEmpty ? 'No tests selected' : plan.join(', ')),
          ),
          for (final t in widget.registry)
            Card(
              child: ListTile(
                leading: Icon(t.icon),
                title: Text(t.title),
                subtitle: Text('id: ${t.id}'),
                trailing: Checkbox(
                  value: selectedIds.contains(t.id),
                  onChanged: (_) {
                    setState(() {
                      if (selectedIds.contains(t.id)) {
                        selectedIds.remove(t.id);
                      } else {
                        selectedIds.add(t.id);
                      }
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    if (selectedIds.contains(t.id)) {
                      selectedIds.remove(t.id);
                    } else {
                      selectedIds.add(t.id);
                    }
                  });
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: plan.isEmpty
                  ? null
                  : () => ref.read(sessionProvider.notifier).start(plan),
              child: const Text('Start session'),
            ),
          ),
        ],
      ),
    );
  }
}
