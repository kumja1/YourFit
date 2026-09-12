import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:auto_route/auto_route.dart';
import 'package:extensions_plus/extensions_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:open_route_service/open_route_service.dart';
import 'package:yourfit/src/models/exercise/running_exercise_data.dart';
import 'package:yourfit/src/screens/other/exercises/basic_exercise_screen.dart';
import 'package:yourfit/src/services/device_service.dart';
import 'package:yourfit/src/utils/functions/index.dart';
import 'package:yourfit/src/widgets/other/navigation_map.dart';

@RoutePage()
class RunningExerciseScreen extends BasicExerciseScreen {
  const RunningExerciseScreen({
    super.key,
    required super.exercise,
    required super.onSetComplete,
    required super.onExerciseComplete,
  });

  @override
  Widget build(BuildContext context) {
    final controller = _RunningExerciseScreenController(exercise: exercise as RunningExerciseData);
    return Scaffold(
      body: FutureBuilder(
        future: controller.init(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(color: Colors.blue).center();
          }

          if (snapshot.hasError || snapshot.data == false) {
            if (snapshot.hasError) {
              logger.severe("Error in RunningExerciseScreen", snapshot.error);
            }

            return const SizedBox.shrink();
          }

          return NavigationMap(
            route: controller.route!,
            onDestinationReached: onExerciseComplete,
          );
        },
      ),
    );
  }
}

class _RunningExerciseScreenController {
  final RunningExerciseData exercise;
  final DeviceService deviceService = Get.find<DeviceService>();

  late ({
    Position start,
    Map<String, dynamic> segmentJson,
    DirectionRouteSegment segment,
    GeoJsonFeatureGeometry geometry,
  })?
  route;

  _RunningExerciseScreenController({required this.exercise});

  Future<bool> init() async {
    try {
      route = await deviceService.getRouteFromDevicePosition(
        targetLongitude: -77.46844980291,
        targetLatitude: 37.620874568397,
      );

      if (route == null || route!.segment.steps.isEmpty) {
        logger.severe("Route is null or has no steps!");
        return false;
      }

      return true;
    } on Error catch (e) {
      logger.severe("Error in _RunningExerciseScreenController.init", e);
      // showSnackbar(e.toString(), AnimatedSnackBarType.error);
      return false;
    }
  }
}
