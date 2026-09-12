// lib/src/screens/tabs/roadmap/widgets/daily_summary_widgets.dart
import 'package:material_ui/material_ui.dart';
import 'package:yourfit/src/models/exercise/index.dart';

class AiGenerationBanner extends StatelessWidget {
  const AiGenerationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: const Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Creating personalized monthly schedule...',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectedWorkoutCard extends StatelessWidget {
  final WorkoutFocus? workout;
  const SelectedWorkoutCard({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: workout == null
          ? const SizedBox.shrink()
          : Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    workout!.color.withValues(alpha: 0.10),
                    workout!.color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: workout!.color.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  Icon(workout!.icon, color: workout!.color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      workout!.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: workout!.color.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
