import 'package:cupertino_ui/cupertino_ui.dart';

abstract class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Map<String, dynamic>? getData();
  bool canProgress() => false;
}
