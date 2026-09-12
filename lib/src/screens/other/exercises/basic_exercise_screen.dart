import 'package:auto_route/auto_route.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:extensions_plus/extensions_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:rxget/rxget.dart';
import 'package:yourfit/src/models/exercise/exercise_data.dart';
import 'package:yourfit/src/routing/index.dart';
import 'package:yourfit/src/widgets/buttons/animated_button.dart';

@RoutePage()
class BasicExerciseScreen extends StatelessWidget {
  final ExerciseData exercise;
  final VoidCallback onSetComplete;
  final VoidCallback onExerciseComplete;

  const BasicExerciseScreen({
    super.key,
    required this.exercise,
    required this.onSetComplete,
    required this.onExerciseComplete,
  });

  @override
  Widget build(BuildContext context) {
    final controller = _BasicExerciseScreenController(
      exercise,
      onExerciseComplete,
      onSetComplete,
    );

    final started = controller.started;
    final setsDone = controller.exercise.state.setsDone;

    return Obx(() => Scaffold(
      body:  !started.value
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Instructions", style: Theme.of(context).textTheme.headlineMedium,),
                  const SizedBox(height: 10),
                  Text(
                    exercise.instructions,
                    style: const TextStyle(color: Colors.black38),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                  const SizedBox(height: 15),
                  AnimatedButton(
                    onPressed: controller.toggleStarted,
                    child: const Text(
                      "Continue",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                 StepProgressIndicator(
                      size: 10,
                      totalSteps: controller.exercise.sets,
                      padding: 0,
                      currentStep: setsDone.value,
                      roundedEdges: const Radius.circular(10),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      unselectedColor: Colors.grey[200]!,
                      selectedColor: Colors.blue,
                      progressDirection: TextDirection.ltr,
                    ).paddingOnly(left: 30, right: 30, top: 20),
                  Align(
                    alignment: Alignment.center,
                    child: CircularCountDownTimer(
                      duration: controller.exercise.setDuration.inSeconds,
                      autoStart: true,
                      controller: controller.countdownController,
                      isReverse: true,
                      isReverseAnimation: true,
                      isTimerTextShown: true,
                      textFormat: CountdownTextFormat.MM_SS,
                      onComplete: controller.completeSet,
                      ringColor: Colors.grey[200]!,
                      fillColor: Colors.blue,
                      backgroundColor: Colors.transparent,
                      strokeWidth: 12.0,
                      strokeCap: StrokeCap.round,
                      textStyle: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      width: 90,
                      height: 90,
                    ),
                  ).flexible(),
                ],
              ),
    ));
  }
}

class _BasicExerciseScreenController {
  final ExerciseData exercise;
  final VoidCallback onSetComplete;
  final VoidCallback onExerciseComplete;
  final CountDownController countdownController = CountDownController();
  final AppRouter router = Get.find<AppRouter>();
  final Rx<bool> started = false.obs;

  _BasicExerciseScreenController(
    this.exercise,
    this.onExerciseComplete,
    this.onSetComplete,
  );

  void toggleStarted() {
    started.value = !started.value;
  }

  void completeExercise() {
    exercise.state.completed.value = true;

    router.back();
    onExerciseComplete();
  }

  void completeSet() {
    if (exercise.state.setsDone.value++ >= exercise.sets - 1) {
      completeExercise();
      return;
    }

    onSetComplete();
    countdownController.restart();
  }
}
