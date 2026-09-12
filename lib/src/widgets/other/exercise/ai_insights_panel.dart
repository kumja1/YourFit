import 'package:material_ui/material_ui.dart';
import 'package:rxget/rxget.dart';

class AiInsightsPanel extends StatelessWidget {
  const AiInsightsPanel({
    super.key,
    this.explanation,
    required this.onTweak,
    required this.loading,
  });

  final String? explanation;
  final Future<void> Function(String instruction) onTweak;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.psychology, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'AI Insights',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                GetBuilder<_AiInsightsPanelController>(
                  init: _AiInsightsPanelController(onTweak),
                  builder: (controller) => IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: controller.expanded ? 'Collapse' : 'Expand',
                    icon: controller.expanded
                        ? const Icon(Icons.expand_less)
                        : const Icon(Icons.expand_more),
                    onPressed: controller.toggleExpanded,
                  ),
                ),
              ],
            ),

            // Panel content
            GetBuilder<_AiInsightsPanelController>(
              builder: (controller) {
                if (controller.expanded) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Explanation
                    Text(
                      explanation.isBlank!
                          ? 'No AI notes yet. Generate a plan to see analysis.'
                          : explanation!,
                      style: TextStyle(
                        color: explanation.isBlank!
                            ? theme.hintColor
                            : theme.textTheme.bodySmall?.color,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick tweaks
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Make easier'),
                          onPressed: loading
                              ? null
                              : () => controller.send(
                                  loading,
                                  'Make the overall workout easier. Reduce sets/reps and sub hard moves.',
                                ),
                        ),
                        ActionChip(
                          label: const Text('Make harder'),
                          onPressed: loading
                              ? null
                              : () => controller.send(
                                  loading,
                                  'Increase difficulty. Add progressive overload, more sets or harder variations.',
                                ),
                        ),
                        ActionChip(
                          label: const Text('Add more cardio'),
                          onPressed: loading
                              ? null
                              : () => controller.send(
                                  loading,
                                  'Add more cardio focus. Include HIIT or steady-state blocks.',
                                ),
                        ),
                        ActionChip(
                          label: const Text('Focus core'),
                          onPressed: loading
                              ? null
                              : () => controller.send(
                                  loading,
                                  'Shift the workout to emphasize core/abs.',
                                ),
                        ),
                        ActionChip(
                          label: const Text('Upper body bias'),
                          onPressed: loading
                              ? null
                              : () => controller.send(
                                  loading,
                                  'Bias the workout towards upper body.',
                                ),
                        ),
                        ActionChip(
                          label: const Text('Lower body bias'),
                          onPressed: loading
                              ? null
                              : () => controller.send(
                                  loading,
                                  'Bias the workout towards lower body.',
                                ),
                        ),
                        ActionChip(
                          label: const Text('20-min version'),
                          onPressed: loading
                              ? null
                              : () => controller.send(
                                  loading,
                                  'Shorten to a compact 20-minute routine.',
                                ),
                        ),
                        ActionChip(
                          label: const Text('Equipment-free'),
                          onPressed: loading
                              ? null
                              : () => controller.send(
                                  loading,
                                  'Replace exercises with bodyweight/no-equipment variants.',
                                ),
                        ),
                        ActionChip(
                          label: const Text('Low-impact'),
                          onPressed: loading
                              ? null
                              : () => controller.send(
                                  loading,
                                  'Make it low-impact and joint-friendly.',
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Custom tweak input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            enabled: !loading,
                            decoration: const InputDecoration(
                              hintText:
                                  'Custom tweak (e.g., “swap push-ups for dumbbell press”)',
                              isDense: true,
                            ),
                            onSubmitted: (s) => controller.send(loading, s),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: loading
                              ? null
                              : () => controller.send(
                                  loading,
                                  controller.textController.text,
                                ),
                          icon: loading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_fix_high),
                          label: const Text('Tweak'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AiInsightsPanelController extends GetxController<_AiInsightsPanelState> {
  @override
  final _AiInsightsPanelState state = _AiInsightsPanelState();
  final textController = TextEditingController();
  bool expanded = true;

  final Future<void> Function(String instruction) onTweak;

  _AiInsightsPanelController(this.onTweak);

  void send(bool loading, String instruction) {
    if (loading || instruction.isBlank!) return;

    onTweak(instruction);
    if (textController.text.isNotEmpty) {
      textController.clear();
    }

    final class _AiInsightsPanelState extends GetxState {
      @override
      void onClose() {}
    }
  }

  void toggleExpanded() {
    expanded = !expanded;
    update();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
