import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/providers/test_providers.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/l10n/strings.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';
import 'package:flutter_master_app/providers/language_provider.dart';

/// Helper function to get localized test title
String getLocalizedTestTitle(String testId, AppStrings strings) {
  switch (testId) {
    case 'Counter Test':
      return strings.counterTest;
    case 'Trykk 10 Test':
      return strings.tap10Test;
    case 'Mini-Cog Test':
      return strings.cogTest;
    case 'Trail Making Test':
      return strings.tmtTest;
    case 'Stroop Test':
      return strings.stroopTest;
    case 'Stroop Test - Old':
      return '${strings.stroopTest} (Old)';
    default:
      return testId;
  }
}

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
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              strings.selectTests,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.crayolaBlue,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              children: [
                for (final t in widget.registry)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          ? AppColors.crayolaBlue
                          : AppColors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: selectedIds.contains(t.id)
                                ? AppColors.white
                                : AppColors.lavender,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            t.icon,
                            color: selectedIds.contains(t.id)
                                ? AppColors.crayolaBlue
                                : AppColors.crayolaBlue,
                            size: 32,
                          ),
                        ),
                        title: Text(
                          getLocalizedTestTitle(t.id, strings),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: selectedIds.contains(t.id)
                                    ? AppColors.white
                                    : AppColors.crayolaBlue,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        trailing: Material(
                          color: Colors.transparent,
                          child: Checkbox(
                            activeColor: selectedIds.contains(t.id)
                                ? AppColors.white
                                : AppColors.crayolaBlue,
                            checkColor: selectedIds.contains(t.id)
                                ? AppColors.crayolaBlue
                                : AppColors.white,
                            side: !selectedIds.contains(t.id)
                                ? const BorderSide(
                                    color: AppColors.crayolaBlue,
                                    width: 2,
                                  )
                                : BorderSide.none,
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
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomButtonBar(
        actionButtons: [
          BottomButton(
            label: strings.back,
            onPressed: () => ref.read(sessionProvider.notifier).returnToMenu(),
            icon: Icons.arrow_back,
          ),
          BottomButton(
            label: strings.start,
            onPressed: () {
              ref.read(sessionPointsProvider.notifier).reset();
              ref.read(sessionProvider.notifier).start(plan);
            },
            enabled: plan.isNotEmpty,
            icon: Icons.play_arrow,
          ),
        ],
        showAbortButton: false,
        useRow: true,
      ),
    );
  }
}
