import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:logging/logging.dart';
import 'package:yourfit/src/services/device_service.dart';
import 'package:yourfit/src/services/index.dart';
import 'package:yourfit/src/utils/objects/constants/env/env.dart';
import 'package:rxget/rxget.dart';

Future<void> initServices() async {
  // Initialize Supabase, Google Sign In
  await Future.wait([
    Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseKey),
    GoogleSignIn.instance.initialize(
      serverClientId: kIsWeb
          ? null
          : "49363448521-ka0refci22k8s3mvvkq1uisdbn06g6vh.apps.googleusercontent.com",
      clientId:
          "49363448521-ka0refci22k8s3mvvkq1uisdbn06g6vh.apps.googleusercontent.com",
    ),
  ]);

  final deviceService = DeviceService();
  await deviceService.initPreferences();

  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<UserService>(UserService(), permanent: true);
  Get.put<ExerciseService>(ExerciseService(), permanent: true);
  Get.put<DeviceService>(deviceService, permanent: true);
  Get.put<Logger>(logger, permanent: true);

  initBackgroundServices();
}

Future<void> initBackgroundServices() async {
  final workManager = Workmanager();
  workManager.initialize(
    () => workManager.executeTask((task, data) async {
      return true;
    }),
  );
  Get.put<Workmanager>(workManager, permanent: true);
}