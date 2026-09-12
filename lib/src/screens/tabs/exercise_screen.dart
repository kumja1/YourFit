// lib/src/screens/tabs/exercise/workouts_screen.dart
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:langchain/langchain.dart';
import 'package:logging/logging.dart';
import 'package:yourfit/src/models/exercise/running_exercise_data.dart';
import 'package:yourfit/src/models/index.dart';
import 'package:yourfit/src/routing/router.gr.dart';
import 'package:yourfit/src/services/device_service.dart';
import 'package:yourfit/src/services/index.dart';
import 'package:yourfit/src/utils/functions/show_snackbar.dart';
import 'package:yourfit/src/widgets/other/exercise/index.dart';
import 'package:rxget/rxget.dart';

@RoutePage()
class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_ExerciseScreenController());
    return Scaffold(
      floatingActionButton: GetBuilder<_ExerciseScreenController>(
        id: "loading",
        builder: (c) => FloatingActionButton.extended(
          onPressed: c.loading ? null : c.generate,
          icon: c.loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh),
          label: const Text('New Plan', style: TextStyle(color: Colors.blue)),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  minExtentVal: 84,
                  maxExtentVal: 120,
                  child: Material(
                    elevation: 2,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Obx(
                        () => CompactHeader(
                          level: controller.currentStats?.level ?? 1,
                          xp: controller.currentStats?.xp ?? 0,
                          xpToNext: controller.currentStats?.xpToNext ?? 0,
                          streak: controller.currentStats?.streak ?? 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TODAY'S FOCUS",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          GetBuilder<_ExerciseScreenController>(
                            builder: (controller) =>
                                controller.workout?.focus == null
                                ? const SizedBox.shrink()
                                : Text(
                                    controller.workout!.focus.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: GetBuilder<_ExerciseScreenController>(
                    id: "loading",
                    builder: (controller) => AiInsightsPanel(
                      loading: controller.loading,
                      explanation: "",
                      onTweak: controller.modifyWorkout,
                    ),
                  ),
                ),
              ),
              GetBuilder<_ExerciseScreenController>(
                builder: (controller) => controller.loading
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        sliver: SliverList.builder(
                          itemCount: controller.workout?.exercises.length ?? 0,
                          itemBuilder: (_, i) =>
                              controller.workout?.exercises[i] == null
                              ? const SizedBox.shrink()
                              : ExerciseCard(
                                  exercise: controller.workout!.exercises[i],
                                  onClick: (exercise, cardController) {
                                    try {
                                      context.router.push(
                                        exercise is RunningExerciseData
                                            ? RunningExerciseRoute(
                                                exercise: exercise,
                                                onSetComplete: () => controller
                                                    .updateXp(exercise),
                                                onExerciseComplete:
                                                    cardController
                                                        .toggleDisabled,
                                              )
                                            : BasicExerciseRoute(
                                                exercise: exercise,
                                                onSetComplete: () => controller
                                                    .updateXp(exercise),
                                                onExerciseComplete:
                                                    cardController
                                                        .toggleDisabled,
                                              ),
                                      );
                                    } on Error catch (e) {
                                      e.printError();
                                      showSnackbar(
                                        e.toString(),
                                        AnimatedSnackBarType.error,
                                      );
                                    }
                                  },
                                ),
                        ),
                      ),
              ),
            ],
          ),

          Positioned(
            right: 16,
            bottom: 92, // sits above the main FAB
            child: const QaMiniButton(),
          ),
        ],
      ),
    );
  }
}

class _ExerciseScreenController extends GetxController<_ExerciseScreenState> {
  @override
  final _ExerciseScreenState state = _ExerciseScreenState();
  final UserService userService = Get.find();
  final ExerciseService exerciseService = Get.find();
  final DeviceService deviceService = Get.find();
  final Rx<UserData?> currentUser = Get.find<AuthService>().currentUser;
  UserStats? get currentStats => currentUser.value?.stats;

  // ---- Screen State ----
  bool loading = false;
  WorkoutData? workout = WorkoutData(
    focus: WorkoutFocus.cardio,
    caloriesBurned: 450,
    duration: Duration(minutes: 45),
    summary:
        "A comprehensive running workout combining intervals, steady-state runs, and cool-down jog to build endurance and burn calories.",
    exercises: [
      // Warm-up Run
      RunningExerciseData(
        name: "Warm-up Jog",
        difficulty: ExerciseDifficulty.easy,
        intensity: ExerciseIntensity.low,
        type: ExerciseType.cardio,
        caloriesBurned: 60,
        duration: Duration(minutes: 10),
        setDuration: Duration(minutes: 10),
        sets: 1,
        reps: 1,
        distance: 1.5,
        speed: 9, // km/h
        destination: "1200 Westbrook Avenue Richmond, VA, 23227",
        instructions:
            "Start with a light jog to warm up your muscles. Keep your pace comfortable and focus on steady breathing. Land midfoot and maintain good posture.",
        summary: "Easy warm-up jog to prepare your body for the workout.",
        targetMuscles: ["Legs", "Cardiovascular System"],
        equipment: ["Running Shoes"],
      ),

      // Interval Training
      RunningExerciseData(
        name: "Sprint Intervals",
        difficulty: ExerciseDifficulty.hard,
        intensity: ExerciseIntensity.high,
        type: ExerciseType.cardio,
        caloriesBurned: 180,
        duration: Duration(minutes: 20),
        setDuration: Duration(minutes: 2),
        sets: 6,
        reps: 1,
        distance: 3.0,
        speed: 15, // km/h during sprints
        destination: "200 Tredegar St, Richmond, VA 23219",
        instructions:
            "Sprint at 80-90% max effort for 1 minute, then recover jog for 1 minute. Repeat for 6 sets. Focus on explosive power and maintaining form even when tired.",
        summary:
            "High-intensity interval training to boost speed and endurance.",
        targetMuscles: ["Quadriceps", "Hamstrings", "Calves", "Glutes"],
        equipment: ["Running Shoes", "Water Bottle"],
        restIntervals: [
          RestInterval(duration: Duration(minutes: 1), restAt: 1),
          RestInterval(duration: Duration(minutes: 1), restAt: 2),
          RestInterval(duration: Duration(minutes: 1), restAt: 3),
          RestInterval(duration: Duration(minutes: 1), restAt: 4),
          RestInterval(duration: Duration(minutes: 1), restAt: 5),
        ],
      ),

      // Tempo Run
      RunningExerciseData(
        name: "Steady Tempo Run",
        difficulty: ExerciseDifficulty.medium,
        intensity: ExerciseIntensity.medium,
        type: ExerciseType.cardio,
        caloriesBurned: 150,
        duration: Duration(minutes: 12),
        setDuration: Duration(minutes: 12),
        sets: 1,
        reps: 1,
        distance: 2.0,
        speed: 11, // km/h
        destination: "501 E Byrd St, Richmond, VA 23219",
        instructions:
            "Run at a comfortably hard pace - you should be able to speak in short sentences but not hold a full conversation. Maintain consistent speed throughout.",
        summary: "Moderate-intensity run to build lactate threshold.",
        targetMuscles: ["Legs", "Core", "Cardiovascular System"],
        equipment: ["Running Shoes"],
      ),

      // Cool-down
      RunningExerciseData(
        name: "Cool-down Jog",
        difficulty: ExerciseDifficulty.easy,
        intensity: ExerciseIntensity.low,
        type: ExerciseType.cardio,
        caloriesBurned: 60,
        duration: Duration(minutes: 8),
        setDuration: Duration(minutes: 8),
        sets: 1,
        reps: 1,
        distance: 1.0,
        speed: 8, // km/h
        destination: "1000 E Broad St, Richmond, VA 23219",
        instructions:
            "Gradually reduce your pace to a slow jog. Focus on deep breathing and allowing your heart rate to come down. Finish with light stretching.",
        summary: "Easy cool-down to help recovery and prevent soreness.",
        targetMuscles: ["Legs", "Cardiovascular System"],
        equipment: ["Running Shoes"],
      ),
    ],
  );

  @override
  void onReady() {
    final now = DateTime.now();
    final timestamp =
        deviceService.getDevicePreference<DateTime>(
          "last_generation",
          converter: (v) => DateTime.tryParse(v),
        ) ??
        now;

    if (now.difference(timestamp).inDays < 1) {
      return;
    }

    final class _ExerciseScreenState extends GetxState {
      @override
      void onClose() {}
    }

    deviceService.setDevicePreference(
      "last_generation",
      now,
      converter: (d) => d.toIso8601String(),
    );

    Logger.root.info("Getting existing workout");
    workout = currentUser.value?.getWorkoutData(DateTime.now());
    workout.printInfo();
    update();
    Logger.root.info("Updated UI");
  }

  Future<void> generate() async {
    if (loading) return;
    loading = true;
    update(["loading"]);
    try {
      final result = await exerciseService.getExercises(
        currentUser.value,
        difficulty: currentUser.value?.exercisesDifficulty,
        intensity: currentUser.value?.exercisesIntensity,
        additionalParams: {
          "relative_locations": Parameter(
            description:
                "Relative locations to the user. Used for generating running exercises",
            value: (await deviceService.getPositionsNearDevice()).map(
              (e) => e.toJson(),
            ),
          ),
        },
      );

      if (result == null) return;
      workout = result;
      currentUser.value?.addWorkoutData(workout!);
      userService.updateUser(currentUser.value!);
      update();
      currentUser.value?.toJson().printInfo();
    } on Error catch (e) {
      e.printError();
      showSnackbar(e.toString(), AnimatedSnackBarType.error);
    } finally {
      loading = false;
      update(["loading"]);
    }
  }

  Future<void> modifyWorkout(String instruction) async {
    if (loading || workout == null) return;
    loading = true;
    update(["loading"]);

    try {
      final res = await exerciseService.getExercises(
        currentUser.value,
        prompt: instruction,
        additionalParams: {
          "current_workout": Parameter(
            description: "The workout to modify",
            value: workout?.toJson(),
          ),
        },
        count: workout!.exercises.length,
      );

      workout = res;
    } catch (e) {
      showSnackbar(e.toString(), AnimatedSnackBarType.error);
    } finally {
      loading = false;
      update(["loading"]);
    }
  }

  void updateXp(ExerciseData exercise) {
    final gained =
        8 + (exercise.reps ~/ 5) + (currentUser.value?.stats.streak ?? 0 ~/ 5);

    currentUser.value?.stats.addXp(gained);
    userService.updateUser(currentUser.value!);
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.minExtentVal,
    required this.maxExtentVal,
    required this.child,
  });

  final double minExtentVal;
  final double maxExtentVal;
  final Widget child;

  @override
  double get minExtent => minExtentVal;

  @override
  double get maxExtent => maxExtentVal;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.minExtentVal != minExtentVal ||
        oldDelegate.maxExtentVal != maxExtentVal ||
        oldDelegate.child != child;
  }
}
