import 'package:auto_route/auto_route.dart';
import 'package:yourfit/src/routing/index.dart';
import 'package:yourfit/src/services/index.dart';
import 'package:yourfit/src/utils/index.dart';

class AuthGuard extends AutoRouteGuard {
  final AuthService authService = Get.find<AuthService>();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    await authService.refreshSession();
    if (authService.isSignedIn) {
      resolver.next();
      return;
    }

    router.replacePath(Routes.landing);
  }
}
