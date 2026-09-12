import 'package:dart_mappable/dart_mappable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yourfit/src/models/exercise/exercise_data.dart';

part 'workout_data.mapper.dart';

@MappableEnum()
enum WorkoutFocus {
  leg('Leg Day', Colors.blue, Icons.directions_walk, 'LEG'),
  upperBody('Upper Body', Colors.green, Icons.fitness_center, 'UP'),
  cardio('Cardio', Colors.orange, Icons.directions_run, 'CRD'),
  core('Core', Colors.purple, Icons.self_improvement, 'CORE'),
  fullBody('Full Body', Colors.red, Icons.accessibility_new, 'FB'),
  rest('Rest Day', Colors.grey, Icons.hotel, 'REST'),
  yoga('Yoga/Stretch', Colors.teal, Icons.spa, 'YOG');

  final String label;
  final Color color;
  final IconData icon;
  final String abbrev;
  const WorkoutFocus(this.label, this.color, this.icon, this.abbrev);

  factory WorkoutFocus.fromValue(String value) =>
      WorkoutFocusMapper.fromValue(value);
}

@MappableClass()
class WorkoutData with WorkoutDataMappable {
  final List<ExerciseData> exercises;
  final double caloriesBurned;
  final Duration duration;
  final WorkoutFocus focus;
  final String summary;

  const WorkoutData({
    required this.exercises,
    required this.focus,
    required this.caloriesBurned,
    required this.duration,
    required this.summary,
  });

  factory WorkoutData.fromJson(String json) => WorkoutDataMapper.fromJson(json);

  factory WorkoutData.fromMap(Map<String, dynamic> map) =>
      WorkoutDataMapper.fromMap(map);
}
