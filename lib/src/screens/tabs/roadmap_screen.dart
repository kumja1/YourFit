import 'dart:convert';
import 'package:auto_route/annotations.dart';
import 'package:const_date_time/const_date_time.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart';
import 'package:rxget/rxget.dart';
import 'package:yourfit/src/models/index.dart';
import 'package:yourfit/src/models/nutrition/food_search_result.dart';
import 'package:yourfit/src/models/nutrition/meal_data.dart';
import 'package:yourfit/src/services/device_service.dart';
import 'package:yourfit/src/services/index.dart';
import 'package:yourfit/src/widgets/other/index.dart';

import '../../utils/index.dart';

@RoutePage()
class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: GetBuilder<RoadmapController>(
              init: RoadmapController(),
              builder: (s) => CustomScrollView(
                slivers: [
                  if (s.generatingPlan) const AiGenerationBanner(),
                  RoadmapCalendar(controller: s),
                  SelectedWorkoutCard(workout: s.selectedWorkout),
                  // ADD REGENERATE BUTTON HERE
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: s.generatingPlan
                            ? null
                            : () => s.generateMonthlyPlan(),
                        icon: s.generatingPlan
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(
                          s.generatingPlan
                              ? 'Generating...'
                              : 'Regenerate Monthly Plan',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoadmapController extends GetxController<_RoadmapState> {
  @override
  final _RoadmapState state = _RoadmapState();
  final DeviceService deviceService = Get.find<DeviceService>();
  final Rx<UserData?> currentUser = Get.find<AuthService>().currentUser;

  final searchController = TextEditingController();
  bool loadingSearch = false;
  List<FoodSearchResult> searchResults = [];

  List<MealData> entries = [];
  double totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;
  double totalFiber = 0;
  double totalSugar = 0;
  double totalSodium = 0;

  int waterMl = 0;

  int kcalTarget = 2600;
  int proteinTarget = 110;
  int carbsTarget = 330;
  int fatTarget = 80;
  int fiberTarget = 28;
  int waterTargetMl = 2500;

  bool generatingPlan = false;
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  Map<String, WorkoutFocus> workoutPlans = {};

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  WorkoutFocus? get selectedWorkout => getWorkoutForDate(selectedDay);

  String get selectedDateName =>
      DateUtils.isSameDay(selectedDay, DateTime.now())
      ? "Today"
      : "${_monthName(selectedDay.month)} ${selectedDay.day}, ${selectedDay.year}";

  List<FoodSearchResult> recentFoods = [];

  void init() {
    _initPrefs();
  }

  final class _RoadmapState extends GetxState {
    @override
    void onClose() {}
  }

  Future<void> _initPrefs() async {
    // _loadDay(selectedDay);
    // await _loadWorkoutPlans();
    // _loadTargets();
    //  _loadRecents();
    if (workoutPlans.isEmpty) {
      await generateMonthlyPlan();
    } else {
    }
  }

  String _dateKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  void onDaySelected(DateTime sel, DateTime foc) {
    selectedDay = sel;
    focusedDay = foc;
    // _loadDay(sel);
    searchResults = [];
    update();
  }

  WorkoutFocus? getWorkoutForDate(DateTime date) {
    final key = _dateKey(date);
    return workoutPlans[key];
  }

  Future<void> generateMonthlyPlan() async {
    generatingPlan = true;
    update();

    try {
      final user = currentUser.value;
      // final plan = await _generateAIPlan(age, activity);
      //   await _savePlans(plan);
      // workoutPlans = plan;

      // Get.snackbar(
      //   'Success',
      //   'Monthly workout plan generated!',
      //   snackPosition: SnackPosition.BOTTOM,
      //   duration: const Duration(seconds: 2),
      // );
    } on Error catch (e) {
      e.printError();
      // workoutPlans = _generateDefaultPlan();
      // Get.log("Using default workout plan");
    }

    generatingPlan = false;
    update();
  }

  WorkoutFocus? _parseWorkoutType(String raw) {
    final s = raw.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    if (s.contains('rest')) return WorkoutFocus.rest;
    if (s.contains('full')) return WorkoutFocus.fullBody;
    if (s.contains('upper') || s.contains('push') || s.contains('pull')) {
      return WorkoutFocus.upperBody;
    }
    if (s.contains('leg') || s.contains('lower')) return WorkoutFocus.leg;
    if (s.contains('cardio') || s.contains('hiit') || s.contains('interval')) {
      return WorkoutFocus.cardio;
    }
    if (s.contains('core') || s.contains('abs')) return WorkoutFocus.core;
    if (s.contains('yoga') || s.contains('stretch') || s.contains('mobility')) {
      return WorkoutFocus.yoga;
    }
    return null;
  }


  Future<void> selectDate(BuildContext ctx) async {
    final pick = await showDatePickerDialog(
      context: ctx,
      minDate: currentUser.value?.createdAt ?? const ConstDateTime(1970),
      maxDate: const ConstDateTime(2050),
      currentDate: selectedDay,
      theme: const DatePickerPlusTheme(
        daysPickerTheme: DaysPickerTheme(
          daysOfTheWeekTheme: DaysOfTheWeekTheme(
            textStyle: TextStyle(
              color: Colors.black26,
              fontSize: 14,
            ),

          ),
          enabledCellsTextStyle: TextStyle(
            color: Colors.black26,
            fontSize: 14,
          ),
          currentDateTextStyle: TextStyle(color: Colors.white, fontSize: 14),
          currentDateDecoration:  BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey,
          ),
          selectedCellDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
        ),
        headerTheme: HeaderTheme(
          centerLeadingDate: true,
          leadingDateTextStyle: TextStyle(fontSize: 20),
        )
      ),
      // slidersColor: Colors.black,
      // splashRadius: 20,
    );

    if (pick == null) {
      return;
    }

    onDaySelected(pick, pick);
  }

  String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[(m - 1).clamp(0, 11)];
  }
}
