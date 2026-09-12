// lib/src/screens/tabs/exercise/widgets/exercise_card.dart
import 'package:extensions_plus/extensions_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rxget/rxget.dart';
import 'package:yourfit/src/models/exercise/exercise_data.dart';
import 'package:yourfit/src/widgets/buttons/animated_button.dart';

class ExerciseCard extends StatelessWidget {
  final ExerciseData exercise;
  final Function(ExerciseData, ExerciseCardController) onClick;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.maybeWidthOf(context);
    return GetBuilder<ExerciseCardController>(
      init: ExerciseCardController(exercise),
      global: false,
      builder: (controller) => AnimatedButton(
        shadowColor: Colors.black12,
        backgroundColor: controller.disabled ? Colors.grey[200] : Colors.white,
        width: screenWidth,
        height: 80,
        borderRadius: 10,
        onPressed: controller.disabled
            ? null
            : () => onClick(exercise, controller),
        child: ListTile(
          title: Text(
            exercise.name,
            style: TextStyle(
              color: controller.disabled ? const Color(0xFFBDBDBD) : Colors.blue,
            ),
          ),
          titleAlignment: ListTileTitleAlignment.titleHeight,
          subtitle: Text(
            '${exercise.sets} x ${exercise.reps}  •  ${exercise.state.setsDone}/${exercise.sets} sets',
            style: TextStyle(color: const Color(0xFFBDBDBD)),
          ),
          iconColor: Colors.blue,
          // children: [Text(exercise.summary)],
        ).responsiveConstrains(maxWidth: 290, maxHeight: 78),
      ).paddingAll(10),
    );
  }
}

class ExerciseCardController extends GetxController<_ExerciseCardState> {
  @override
  final _ExerciseCardState state = _ExerciseCardState();
  bool disabled;
  ExerciseCardController(ExerciseData exercise) : disabled = exercise.state.completed;

  void toggleDisabled() {
    disabled = !disabled;
    update();
  }

  final class _ExerciseCardState extends GetxState {
    @override
    void onClose() {}
  }
}
