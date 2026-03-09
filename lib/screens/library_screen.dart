import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/theme/app_theme.dart';

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
      appBar: AppBar(
        title: const Text(
          'Velg tester',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.crayolaBlue,
        elevation: 4,
      ),
      body: ListView(
        children: [
          for (final t in widget.registry)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selectedIds.contains(t.id)
                        ? AppColors.crayolaBlue
                        : AppColors.lavender,
                    width: selectedIds.contains(t.id) ? 3 : 1,
                  ),
                ),
                color: selectedIds.contains(t.id)
                    ? AppColors.lavender.withValues(alpha: 0.3)
                    : AppColors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      t.icon,
                      color: AppColors.crayolaBlue,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    t.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.charcoalBlue,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  trailing: Checkbox(
                    activeColor: AppColors.crayolaBlue,
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
