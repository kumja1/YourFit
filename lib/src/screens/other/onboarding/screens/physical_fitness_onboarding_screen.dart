import 'package:choice/choice.dart';
import 'package:extensions_plus/extensions_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rxget/rxget.dart';
import 'package:yourfit/src/models/user_data.dart';
import 'package:yourfit/src/utils/functions/init_services.dart';
import 'package:yourfit/src/widgets/other/animated_choice_chip.dart';
import 'package:yourfit/src/widgets/other/onboarding_screen.dart';

class PhysicalFitnessOnboardingScreen extends OnboardingScreen {
  PhysicalFitnessOnboardingScreen({super.key});

  // ignore: library_private_types_in_public_api
  final _PhysicalFitnessOnboardingScreenController controller = _PhysicalFitnessOnboardingScreenController();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => InlineChoice<UserPhysicalFitness>.single(
        value: controller.selectedChoice.value,
        onChanged: controller.setChoice,
        itemCount: controller.choices.length,
        itemBuilder: (choiceController, i) => AnimatedChoiceChip(
          selected: choiceController.selected(controller.choices[i]),
          onSelected: choiceController.onSelected(controller.choices[i]),
          selectedShadowColor: Colors.blue.shade300,
          selectedColor: Colors.blue.shade50,
          selectedLabelColor: Colors.blue,
          shadowColor: Colors.black12,
          backgroundColor: Colors.white,
          labelText: controller.choices[i].name.toTitleCase(),
        ),
        listBuilder: (itemBuilder, count) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 15,
          children: List.generate(count, itemBuilder),
        ),
      ),
    );
  }

  @override
  Map<String, dynamic> getData() => {
    "physicalFitness": controller.selectedChoice.value,
  };

  @override
  bool canProgress() => controller.selectedChoice.value != null;
}

class _PhysicalFitnessOnboardingScreenController {
  final choices = [
    UserPhysicalFitness.minimal,
    UserPhysicalFitness.light,
    UserPhysicalFitness.moderate,
    UserPhysicalFitness.extreme,
  ];

  final Rx<UserPhysicalFitness?> selectedChoice = Rx<UserPhysicalFitness?>(null);

  void setChoice(UserPhysicalFitness? choice) {
    selectedChoice.value = choice;
  }
}
