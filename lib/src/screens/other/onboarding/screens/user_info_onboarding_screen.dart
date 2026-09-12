import 'package:const_date_time/const_date_time.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:extensions_plus/extensions_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rxget/rxget.dart';
import 'package:yourfit/src/models/user_data.dart';
import 'package:yourfit/src/utils/functions/init_services.dart';
import 'package:yourfit/src/widgets/other/auth_form.dart';
import 'package:yourfit/src/widgets/other/onboarding_screen.dart';
import 'package:yourfit/src/widgets/textfields/number_form_field.dart';

class UserInfoOnboardingScreen extends OnboardingScreen {
  UserInfoOnboardingScreen({super.key});

  final _UserInfoOnboardingScreenController _controller = Get.put(
    _UserInfoOnboardingScreenController(),
    tag: 'user-info-onboarding',
  );

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormBuilderDropdown<UserGender>(
            name: "gender",
            icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
            items: const [
              DropdownMenuItem<UserGender>(
                value: UserGender.male,
                child: Text("Male"),
              ),
              DropdownMenuItem<UserGender>(
                value: UserGender.female,
                child: Text("Female"),
              ),
            ],
            decoration: const InputDecoration(labelText: "Gender"),
            validator: FormBuilderValidators.required(
              errorText: "Gender is required",
            ),
          ).constrains(maxWidth: 360),
          NumberFormField<double>(name: "weight", labelText: "Weight (lb)"),
          NumberFormField<double>(name: "height", labelText: "Height (cm)"),
        ],
      ).center(),
    );
  }

  @override
  Map<String, dynamic> getData() =>
      _controller.formKey.currentState?.value ?? {};

  @override
  bool canProgress() => _controller.validateForm();
}

class _UserInfoOnboardingScreenController {
  Future<DateTime?> showDateDialog(BuildContext context, DateTime? _) async =>
      await showDatePickerDialog(
        context: context,
        maxDate: const ConstDateTime(3000),
        minDate: const ConstDateTime(1900, 12, 31),
        currentDate: DateTime.now(),
        theme: const DatePickerPlusTheme(
          headerTheme: HeaderTheme(
            centerLeadingDate: true,
            leadingDateTextStyle: TextStyle(fontSize: 20),
          ),
          daysPickerTheme: DaysPickerTheme(
            currentDateTextStyle: TextStyle(color: Colors.white, fontSize: 14),
            currentDateDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black26,
            ),
            daysOfTheWeekTheme: DaysOfTheWeekTheme(
              textStyle: TextStyle(color: Colors.black26, fontSize: 14),
            ),
            enabledCellsTextStyle: TextStyle(
              color: Colors.black26,
              fontSize: 14,
            ),
            selectedCellDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
            inkResponseTheme: InkResponseTheme(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          rangePickerTheme: RangePickerTheme(),
        ),

        // slidersColor: Colors.black,
      );
}
