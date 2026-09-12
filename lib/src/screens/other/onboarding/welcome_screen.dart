import 'package:auto_route/auto_route.dart';
import 'package:extensions_plus/extensions_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:rxget/rxget.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:yourfit/src/routing/router.dart';
import 'package:yourfit/src/routing/router.gr.dart';
import 'package:yourfit/src/screens/other/onboarding/screens/physical_fitness_onboarding_screen.dart';
import 'package:yourfit/src/screens/other/onboarding/screens/user_info_onboarding_screen.dart';
import 'package:yourfit/src/utils/index.dart';
import 'package:yourfit/src/widgets/buttons/animated_button.dart';
import 'package:yourfit/src/widgets/other/onboarding_screen.dart';

@RoutePage()
class WelcomeScreen extends StatelessWidget {
  WelcomeScreen({super.key});

  final String _tag = UniqueKey().toString();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_WelcomeScreenController(), tag: _tag);

    return IntroductionScreen(
      key: controller.onboardingKey,
      bodyPadding: EdgeInsets.only(bottom: 0),
      animationDuration: 800,
      rawPages: controller.pages,
      showDoneButton: false,
      showNextButton: false,
      isProgress: false,
      globalHeader: Stack(
        children: [
          Obx(
            () => IconButton(
              constraints: BoxConstraints.tightFor(width: 29.5, height: 29.5),
              iconSize: 30,
              onPressed: () => controller.previous(),
              icon: Icon(
                Icons.keyboard_arrow_left_rounded,
                color: Colors.black12,
              ),
            ).showIf(controller.currentIndex.value >= 1),
          ).align(Alignment.centerLeft).fill(),
          ),
          Obx(
          () => StepProgressIndicator(
              size: 10,
              totalSteps: controller.pages.length,
              padding: 0,
              currentStep: controller.currentIndex.value,
              roundedEdges: const Radius.circular(10),
              crossAxisAlignment: CrossAxisAlignment.start,
              unselectedColor: Colors.grey[200]!,
              selectedColor: Colors.blue,
              progressDirection: TextDirection.ltr,
            ),
          ).paddingOnly(left: 30, right: 30, top: 20),
        ],
      ),
      globalFooter: SizedBox(
        height: 100,
        child: AnimatedButton(
          onPressed: () => controller.next(),
          child: const Text("Continue", style: TextStyle(color: Colors.white)),
        ).center(),
      ),
    );
  }
}

class _WelcomeScreenController extends RxController {
  final onboardingKey = GlobalKey<IntroductionScreenState>();
  final AppRouter router = Get.find<AppRouter>();

  final List<OnboardingScreen> pages = const [
    UserInfoOnboardingScreen(),
    PhysicalFitnessOnboardingScreen(),
  ];

  final Rx<int> currentIndex = 0.obs;
  int previousIndex = 0;
  Map<String, dynamic> onboardingData = {};

  void setCurrentIndex(int index) {
    if (index > pages.length || index < 0) return;
    previousIndex = currentIndex.value;
    currentIndex.value = index;

    final data = pages[previousIndex].getData();
    if (data != null) {
      onboardingData.addAll(data);
    }
  }

  @override
  void dispose() {
    super.dispose();
    onboardingKey.currentState?.dispose();
  }

  void next() {
    bool progress = pages[currentIndex].canProgress();
    if (progress) {
      onboardingKey.currentState?.next();
      setCurrentIndex(currentIndex.value + 1);
      if (currentIndex.value == pages.length) {
        router.popAndPush(SignUpRoute(onboardingData: onboardingData));
      }
    }
  }

  void previous() {
    setCurrentIndex(currentIndex.value - 1);
    onboardingKey.currentState?.previous();
  }
}
