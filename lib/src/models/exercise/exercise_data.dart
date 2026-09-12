import 'package:dart_mappable/dart_mappable.dart';
import 'package:rxget/rxget.dart';

part 'exercise_data.mapper.dart';

@MappableEnum()
enum ExerciseDifficulty {
  easy,
  medium,
  hard;

  factory ExerciseDifficulty.fromValue(String value) =>
      ExerciseDifficultyMapper.fromValue(value);
}

@MappableEnum()
enum ExerciseIntensity {
  low,
  medium,
  high;

  factory ExerciseIntensity.fromValue(String value) =>
      ExerciseIntensityMapper.fromValue(value);
}

@MappableEnum()
enum ExerciseType {
  strength,
  cardio,
  flexibility,
  balance;

  factory ExerciseType.fromValue(String value) =>
      ExerciseTypeMapper.fromValue(value);
}

@MappableClass(discriminatorKey: "model_type")
abstract class ExerciseDataBase with ExerciseDataBaseMappable {
}

@MappableClass(
  includeCustomMappers: [_DurationMapper()],
  discriminatorValue: "basic",
)
class ExerciseData extends ExerciseDataBase with ExerciseDataMappable {
  final ExerciseDifficulty difficulty;
  final ExerciseIntensity intensity;
  final ExerciseType type;
  final Duration duration; // Total duration of the exercise
  final Duration setDuration; // Duration of each set
  final double caloriesBurned;
  final String instructions;
  final String summary;

  final List<RestInterval> restIntervals;
  final List<String> equipment;
  final List<String> targetMuscles;
  final String name;
  final int sets;
  final int reps;
  final ExerciseState _state = ExerciseState(completed: false, setsDone: 0);
  ExerciseState get state => _state;

  ExerciseData({
    required this.difficulty,
    required this.intensity,
    required this.type,
    required this.caloriesBurned,
    required this.name,
    required this.instructions,
    required this.summary,
    required this.sets,
    required this.reps,
    required this.duration,
    required this.setDuration,
    this.targetMuscles = const [],
    this.equipment = const [],
    this.restIntervals = const [],
  });

  factory ExerciseData.fromJson(String json) =>
      ExerciseDataMapper.fromJson(json);

  factory ExerciseData.fromMap(Map<String, dynamic> map) =>
      ExerciseDataMapper.fromMap(map);
}

@MappableClass(includeCustomMappers: [_DurationMapper()])
class RestInterval with RestIntervalMappable {
  final Duration duration;
  final int restAt;
  RestInterval({required this.duration, required this.restAt});

  factory RestInterval.fromJson(String json) =>
      RestIntervalMapper.fromJson(json);

  factory RestInterval.fromMap(Map<String, dynamic> map) =>
      RestIntervalMapper.fromMap(map);
}

@MappableClass()
class ExerciseState with ExerciseStateMappable {
  Rx<bool> completed;
  Rx<int> setsDone;

  ExerciseState({required bool completed, required int setsDone})
    : completed = Rx<bool>(completed),
      setsDone = Rx<int>(setsDone);

  factory ExerciseState.fromJson(String json) =>
      ExerciseStateMapper.fromJson(json);

  factory ExerciseState.fromMap(Map<String, dynamic> map) =>
      ExerciseStateMapper.fromMap(map);
}


class _DurationMapper extends SimpleMapper<Duration> {
  const _DurationMapper();

  @override
  Object? encode(Duration self) => {"inSeconds": self.inSeconds};

  @override
  Duration decode(Object? self) => self is Map<String, dynamic>
      ? Duration(seconds: self["inSeconds"])
      : throw Exception("Invalid type");
}
