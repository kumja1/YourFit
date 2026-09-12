import 'dart:core';
import 'package:const_date_time/const_date_time.dart';
import 'package:extensions_plus/extensions_plus.dart';
import 'package:health/health.dart';
import 'package:yourfit/src/utils/functions/init_logging.dart';
import 'package:yourfit/src/utils/functions/init_services.dart';

import 'device_service.dart';

class HealthConnectService {
  final deviceService = Get.find<DeviceService>();
  final health = Health();

  bool _enabled = false;

  Future<void> init() async {
    _enabled = await _requestHealthDataPermissions();
  }

  Future<bool> _requestHealthDataPermissions() async {
    try {
      if (!(await health.isHealthConnectAvailable())) {
        await health.installHealthConnect();
      }

      if (deviceService.getDevicePreference<bool>("health_connect_enabled") ==
          true) {
        return true;
      }

      bool allowed = false;
      if (!(await health.isHealthDataHistoryAuthorized())) {
        allowed = await health.requestHealthDataHistoryAuthorization();
      }

      if (!(await health.isHealthDataInBackgroundAvailable())) {
        allowed = await health.requestHealthDataInBackgroundAuthorization();
      }

      if ((await health.hasPermissions(dataTypeKeysAndroid)) == false) {
        allowed = await health.requestAuthorization(
          dataTypeKeysAndroid,
          permissions: [HealthDataAccess.READ_WRITE],
          // permissions: [HealthDataAccess.] - Specify READ_WRITE permissions for HealthDataType.WORKOUT
        );
      }

      deviceService.setDevicePreference("health_connect_enabled", allowed);
      return allowed;
    } on Error catch (e) {
      logger.severe("Error in _requestHealthDataPermissions", e);
      return false;
    }
  }

  Future<int?> getTotalSteps({DateTime? from, DateTime? to}) async {
    if (!_enabled) {
      return 0;
    }

    to ??= DateTime.now();
    from ??= to.startOfDay;
    return await health.getTotalStepsInInterval(from, to);
  }

  Future<List<HealthDataPoint?>> getHealthData({
    DateTime? from,
    DateTime? to,
    List<HealthDataType> types = const [],
  }) async {
    if (!_enabled) {
      return [];
    }

    to ??= DateTime.now();
    from = to.startOfDay;

    return (await health.getHealthDataFromTypes(
      types: types,
      startTime: from,
      endTime: to,
      preferredUnits: {},
    ));

    // health.getHealthIntervalDataFromTypes(startDate: startDate, endDate: endDate, types: types, interval: interval)
  }
}
