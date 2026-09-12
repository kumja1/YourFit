import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:auto_route/annotations.dart';
import 'package:extensions_plus/extensions_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:yourfit/src/models/index.dart';
import 'package:yourfit/src/routing/index.dart';
import 'package:yourfit/src/services/auth_service.dart';
import 'package:yourfit/src/services/user_service.dart';
import 'package:yourfit/src/utils/functions/init_services.dart';
import 'package:yourfit/src/utils/functions/show_snackbar.dart';
import 'package:yourfit/src/widgets/index.dart';
import 'package:rxget/rxget.dart';

@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_ProfileScreenController());
    return Scaffold(
      body: Center(
        child: Column(
          spacing: 16,
          children: [
            _ProfileHeader(controller: controller),
            const SizedBox(height: 16),

            _GoalSection(controller: controller),
            const SizedBox(height: 16),

            _TrainingSection(controller: controller),
            const SizedBox(height: 16),

            _EquipmentSection(controller: controller),
            const SizedBox(height: 16),

            AnimatedButton(
              onPressed: () => controller.signOut(),
              backgroundColor: Colors.white,
              shadowColor: Colors.black12,
              child: const Text(
                "Sign Out",
                style: TextStyle(color: Colors.blue),
              ),
            ).align(Alignment.bottomCenter),
          ],
        ),
      ).scrollable().safeArea(),
    );
  }

}

class _ProfileScreenController {
  final AuthService authService = Get.find<AuthService>();
  final Rx<UserData?> currentUser = Get.find<AuthService>().currentUser;
  final UserService userService = Get.find<UserService>();
  final AppRouter router = Get.find<AppRouter>();
  final formKey = GlobalKey<FormBuilderState>();

  void editBasics(BuildContext context) async {
    if (currentUser.value == null) return;
    await showBottomFormSheet(context: context,
      title: 'Edit Basics',
      fields: [
        FormBuilderTextField(
          name: "name",
          initialValue: currentUser.value?.fullName,
          validator: FormBuilderValidators.match(RegExp(r"^\S+ \S+(?: \S+)*$")),
        ),
        FormBuilderDropdown<UserGender>(
          name: "gender",
          initialValue: currentUser.value?.gender,
          items: [UserGender.male, UserGender.female]
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.name.toTitleCase()),
                ),
              )
              .toList(),
          decoration: const InputDecoration(
            labelText: 'Gender',
            border: OutlineInputBorder(),
          ),
        ),
        NumberFormField(
          name: "height",
          initialValue: currentUser.value?.height,
          labelText: 'Height (cm)',
        ),
        NumberFormField(
          name: "weight",
          initialValue: currentUser.value?.weight,
          labelText: 'Weight (lb)',
        ),
      ],
    );
  }

  void editGoal(BuildContext context) async {
    if (currentUser.value == null) return;

    await showBottomFormSheet(context: context,
      title: 'Edit Goal',
      fields: [
        FormBuilderTextField(
          name: "goal",
          initialValue: currentUser.value?.goal,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Goal'),
        ),
      ],
    );
  }

  void editTraining(BuildContext context) async {
    if (currentUser.value == null) return;
    await showBottomFormSheet(context: context,
      title: 'Edit Training',
      fields: [
        FormBuilderDropdown(
          name: "physicalFitness",
          initialValue: currentUser.value?.physicalFitness,
          items: UserPhysicalFitness.values
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.name.toTitleCase()),
                ),
              )
              .toList(),
          decoration: const InputDecoration(labelText: 'Activity'),
        ),
        NumberFormField(
          name: "exerciseDaysPerWeek",
          labelText: "Days / week",
          initialValue: currentUser.value?.exerciseDaysPerWeek,
        ),
        FormBuilderDropdown(
          name: "exercisesIntensity",
          initialValue: currentUser.value?.exercisesIntensity,
          items: ExerciseIntensity.values
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.name.toTitleCase()),
                ),
              )
              .toList(),
          decoration: const InputDecoration(labelText: 'Intensity'),
        ),
      ],
    );
  }

  void editEquipment(BuildContext context) async {
    if (currentUser.value == null) return;
    await showBottomFormSheet(context: context,
      title: 'Edit Equipment',
      fields: [
        FormBuilderTextField(
          name: "equipment",
          initialValue: (currentUser.value!.equipment).join(', '),
          maxLines: 2,
          valueTransformer: (v) => v?.split(',') ?? [],
          decoration: const InputDecoration(
            labelText: 'Equipment (comma-separated)',
          ),
        ),
      ],
    );
  }

  void editDisabilities(BuildContext context) async {
    if (currentUser.value == null) return;

    await showBottomFormSheet(context: context,
      title: 'Edit Disabilities',
      fields: [
        FormBuilderTextField(
          name: "disabilities",
          initialValue: (currentUser.value!.disabilities).join(', '),
          maxLines: 2,
          valueTransformer: (v) => v?.split(',') ?? [],
          decoration: const InputDecoration(
            labelText: 'Disabilities (comma-separated)',
          ),
        ),
      ],
    );
  }

  Future<void> showBottomFormSheet({
    required BuildContext context,
    required String title,
    required List<Widget> fields,
  }) async => await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(ctx).viewInsets.bottom + 12,
      ),
      child: FormBuilder(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...fields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: field,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        if (!formKey.currentState!.saveAndValidate()) {
                          return;
                        }

                        Navigator.pop(ctx);
                        if (currentUser.value == null) {
                          return;
                        }

                        currentUser.update((user) {
                          final formValues = formKey.currentState!.value;

                          if (formValues.containsKey('name')) {
                            final name = (formValues['name'] as String).split(
                              " ",
                            );
                            user!.firstName = name[0];
                            user.lastName = name[1];
                          }

                          if (formValues.containsKey('goal')) {
                            user!.goal = formValues['goal'];
                          }

                          if (formValues.containsKey('height')) {
                            user!.height = formValues['height'];
                          }

                          if (formValues.containsKey('weight')) {
                            user!.weight = formValues['weight'];
                          }

                          if (formValues.containsKey('gender')) {
                            user!.gender = formValues['gender'];
                          }

                          if (formValues.containsKey('equipment')) {
                            user!.equipment = formValues['equipment'];
                          }

                          if (formValues.containsKey('disabilities')) {
                            user!.disabilities = formValues['disabilities'];
                          }

                          if (formValues.containsKey('exerciseDaysPerWeek')) {
                            user!.exerciseDaysPerWeek =
                                formValues['exerciseDaysPerWeek'];
                          }

                          if (formValues.containsKey('physicalFitness')) {
                            user!.physicalFitness =
                                formValues['physicalFitness'];
                          }

                          if (formValues.containsKey('exercisesIntensity')) {
                            user!.exercisesIntensity =
                                formValues['exercisesIntensity'];
                          }
                        });

                        await userService.updateUser(currentUser.value!);
                      } on Error catch (e) {
                        e.printError();
                        showSnackbar(
                          "An error ocurred while updating your profile.",
                          AnimatedSnackBarType.error,
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ).scrollable(),
      ),
    ),
  );

  void signOut() async {
    try {
      await authService.signOut();
    } finally {
      router.replacePath(Routes.landing);
    }
  }
}

class _ProfileSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _ProfileSectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final _ProfileScreenController controller;
  final Rx<UserData?> currentUser;

  _ProfileHeader({required this.controller})
    : currentUser = controller.currentUser;

  @override
  Widget build(BuildContext context) {
    return currentUser.value == null
        ? const SizedBox.shrink()
        : Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.black12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Obx(
                      () => Text(
                        currentUser.value?.intials ?? "",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => Text(
                            currentUser.value?.fullName ?? "-",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Obx(
                              () => _Pill(
                                _formatValue(
                                  currentUser.value?.age,
                                  suffix: ' yrs',
                                ),
                              ),
                            ),
                            Obx(
                              () => _Pill(
                                _formatValue(
                                  currentUser.value?.height,
                                  suffix: ' cm',
                                ),
                              ),
                            ),
                            Obx(
                              () => _Pill(
                                _formatValue(
                                  currentUser.value?.weight,
                                  suffix: ' lb',
                                ),
                              ),
                            ),
                            Obx(
                              () => _Pill(
                                currentUser.value?.gender.name.toTitleCase() ??
                                    '—',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => controller.editBasics(context),
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
            ),
          );
  }

  String _formatValue(num? value, {String suffix = ''}) =>
      value == null ? '—' : '$value$suffix';
}

class _GoalSection extends StatelessWidget {
  final _ProfileScreenController controller;
  final Rx<UserData?> currentUser;

  _GoalSection({required this.controller})
    : currentUser = controller.currentUser;

  @override
  Widget build(BuildContext context) {
    return currentUser.value == null
        ? const SizedBox.shrink()
        : _ProfileSectionCard(
            title: 'Goal',
            trailing: IconButton(
              onPressed: () => controller.editGoal(context),
              icon: const Icon(Icons.edit),
            ),
            child: Obx(
              () => Text(
                currentUser.value?.goal ?? '—',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
  }
}

class _TrainingSection extends StatelessWidget {
  final _ProfileScreenController controller;
  final Rx<UserData?> currentUser;

  _TrainingSection({required this.controller})
    : currentUser = controller.currentUser;

  @override
  Widget build(BuildContext context) {
    return currentUser.value == null
        ? const SizedBox.shrink()
        : _ProfileSectionCard(
            title: 'Training',
            trailing: IconButton(
              onPressed: () => controller.editTraining(context),
              icon: const Icon(Icons.edit),
            ),
            child: Column(
              children: [
                Obx(
                  () => _InfoTile(
                    'Fitness',
                    currentUser.value?.physicalFitness.name ?? '—',
                  ),
                ),
                Obx(
                  () => _InfoTile(
                    'Days / week',
                    currentUser.value?.exerciseDaysPerWeek.toString() ?? '—',
                  ),
                ),
                Obx(
                  () => _InfoTile(
                    'Intensity',
                    currentUser.value?.exercisesIntensity.name.toTitleCase() ??
                        '—',
                  ),
                ),
              ],
            ),
          );
  }
}

class _EquipmentSection extends StatelessWidget {
  final _ProfileScreenController controller;
  final Rx<UserData?> currentUser;

  _EquipmentSection({required this.controller})
    : currentUser = controller.currentUser;

  @override
  Widget build(BuildContext context) {
    return currentUser.value == null
        ? const SizedBox.shrink()
        : _ProfileSectionCard(
            title: 'Equipment & Disabilties',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => controller.editEquipment(context),
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () => controller.editDisabilities(context),
                  icon: const Icon(Icons.healing),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => _TagGroup(
                    label: 'Equipment',
                    tags: currentUser.value?.equipment ?? [],
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => _TagGroup(
                    label: 'Disabilities',
                    tags: currentUser.value?.disabilities ?? [],
                  ),
                ),
              ],
            ),
          );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black12),
      color: Colors.white12,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ).paddingAll(12),
  );
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: const BoxDecoration(
      border: Border.fromBorderSide(BorderSide(color: Colors.black12)),
      color: Colors.white60,
      borderRadius: BorderRadius.all(Radius.circular(999)),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
    ),
  );
}

class _TagGroup extends StatelessWidget {
  final String label;
  final List<String> tags;

  const _TagGroup({required this.label, required this.tags});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      tags.isEmpty
          ? const Text('—')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (e) => Chip(
                      label: Text(e),
                      side: const BorderSide(color: Colors.black12),
                      backgroundColor: Colors.grey.shade100,
                    ),
                  )
                  .toList(),
            ),
    ],
  );
}
