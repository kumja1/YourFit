import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:auto_route/auto_route.dart';
import 'package:const_date_time/const_date_time.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import 'package:extensions_plus/extensions_plus.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthResponse;
import 'package:yourfit/src/models/auth/auth_response.dart';
import 'package:yourfit/src/models/auth/new_user_auth_response.dart';
import 'package:yourfit/src/routing/index.dart';
import 'package:yourfit/src/services/index.dart';
import 'package:yourfit/src/utils/index.dart';
import 'package:yourfit/src/widgets/index.dart';
import 'package:rxget/rxget.dart';

@RoutePage()
class SignUpScreen extends StatelessWidget {
  final Map<String, dynamic> onboardingData;

  const SignUpScreen({super.key, required this.onboardingData});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_SignUpScreenController(), tag: 'sign-up');

    return Scaffold(
      body: AuthForm(
        formKey: controller.formKey,
        // title: const Text(
        // "Create your account",
        // style: TextStyle(fontSize: 30),
        // ).paddingSymmetric(vertical: 40),
        oauthButtons: [
          OAuthButton(
            icon: AppIcons.googleIcon,
            onPressed: () => controller.createAccount(
              onboardingData,
              provider: OAuthProvider.google,
            ),
          ),
        ],
        fields: [
          AuthFormTextField(
            labelText: "Name",
            keyboardType: TextInputType.name,
            onChanged: (value) => controller.name = value,
            validator: FormBuilderValidators.match(
              RegExp(r"^\S+ \S+(?: \S+)*$"),
              errorText: "Name must contain a first name and last name",
            ),
          ),
          // FormBuilderDateTimePicker(
          //   name: "dob",
          
          //   onShowPicker: controller.showDateDialog,
          //   decoration: const InputDecoration(labelText: "Date of Birth"),
          //   onChanged: (value) => controller.dob = value,
          //   format: DateFormat.yMMMMEEEEd(),
          //   resetIcon: const Icon(Icons.close_rounded, color: Colors.blue),
          // ).constrains(maxWidth: 360),
          AuthFormTextField(
            labelText: "Email",
            onChanged: (value) => controller.email = value,
            validator: FormBuilderValidators.email(errorText: "Invalid email"),
          ),
          AuthFormTextField(
            labelText: "Password",
            onChanged: (value) => controller.password = value,
            validator: FormBuilderValidators.password(
              errorText: "Password must be at least 6 characters long",
              minLength: 6,
              minLowercaseCount: 0,
              minNumberCount: 0,
              minSpecialCharCount: 0,
              minUppercaseCount: 0,
            ),
            isPassword: true,
          ),
        ],
        onSubmitPressed: () async =>
            await controller.createAccount(onboardingData),

        submitButtonChild: const Text(
          "Create Account",
          style: TextStyle(color: Colors.white),
        ),
        onBottomButtonPressed: () => context.router.pushPath(Routes.signIn),
        bottomButtonChild: const Text(
          "Existing User? Sign in",
          style: TextStyle(color: Colors.black12),
        ),
      ).center(),
    );
  }
}

class _SignUpScreenController extends AuthFormController {
  String name = "";
  DateTime? dob;

  final UserService userService = Get.find<UserService>();
  final AppRouter router = Get.find<AppRouter>();
  final Logger logger = Get.find<Logger>();

  Future<void> createAccount(
    Map<String, dynamic> data, {
    OAuthProvider? provider,
  }) async {
    try {
      if (provider != null) {
        AuthResponse response = await signInWithOAuth(provider);
        if (response is! NewUserAuthResponse) {
          return;
        }

        if (response.code == AuthCode.error) {
          showSnackbar(response.message!, AnimatedSnackBarType.error);
          return;
        }

        await userService.createUserFromData(
          response.newUser,
          weight: data["weight"],
          height: data["height"],
          gender: data["gender"],
          physicalFitness: data["physicalFitness"],
        );
        return;
      }

      if (!validateForm()) return;
      AuthResponse response = await authService.signUpWithPassword(
        email,
        password,
      );

      if (response.code == AuthCode.error) {
        showSnackbar(response.message!, AnimatedSnackBarType.error);
        return;
      }

      final nameParts = name.split(" ");
     final newUser = await userService.createUser(
        response.supabaseUser!.id,
        nameParts[0],
        nameParts[1],
        data["weight"],
        data["height"],
        dob!,
        data["gender"],
        data["physicalFitness"],
      );

      authService.currentUser.value = newUser;
      router.replacePath(Routes.main);
    } catch (e) {
      logger.severe("Error creating account", e);
      showSnackbar(e.toString(), AnimatedSnackBarType.error);
    }
  }

  Future<DateTime?> showDateDialog(
    BuildContext context,
    DateTime? _,
  ) async => await showDatePickerDialog(
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
        daysOfTheWeekTheme: DaysOfTheWeekTheme(
          textStyle: TextStyle(
            color: Colors.black26,
            fontSize: 14,
          ),
        ),
        enabledCellsTextStyle: TextStyle(color: Colors.black26, fontSize: 14),
        currentDateTextStyle: TextStyle(color: Colors.white, fontSize: 14),
        currentDateDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black26,
        ),
        selectedCellDecoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
      ),
        inkResponseTheme: InkResponseTheme(
          borderRadius: BorderRadius.all(Radius.circular(20))
        )
      )
    )
    // slidersColor: Colors.black,
  );
}
