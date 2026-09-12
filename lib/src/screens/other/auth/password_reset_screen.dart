import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:yourfit/src/models/auth/auth_response.dart';
import 'package:yourfit/src/routing/routes.dart';
import 'package:yourfit/src/utils/index.dart';
import 'package:yourfit/src/widgets/index.dart';
import 'package:zenify/zenify.dart';

@RoutePage()
class PasswordResetScreen extends ZenView<PasswordResetScreenController> {
  const PasswordResetScreen({super.key});

  @override
  Widget build(BuildContext context, PasswordResetScreenController controller) {
    bool resetPassword = context.router.current.argsAs<bool>();
    return Scaffold(
      body: Center(
        child: AuthForm(
          key: controller.formKey,
          title: Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: resetPassword
                ? const Text("Reset Password", style: TextStyle(fontSize: 30))
                : const Text("Forget Password", style: TextStyle(fontSize: 30)),
          ),
          showBottomButton: false,
          showOAuth: false,
          fields: [
            AuthFormTextField(
              onChanged: (value) => resetPassword
                  ? controller.password = value
                  : controller.email = value,
              labelText: resetPassword ? "New Password" : "Email",
              validator: resetPassword ? null : FormBuilderValidators.email(errorText: "Invalid Email"),
            ),
          ],
          onSubmitPressed: () => resetPassword
              ? controller.resetPassword()
              : controller.forgetPassword(),
          submitButtonChild: resetPassword
              ? const Text(
                  "Reset Password",
                  style: TextStyle(color: Colors.white),
                )
              : const Text(
                  "Forget Password",
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ),
    );
  }
}

class PasswordResetScreenController extends AuthFormController {
  Future<AuthResponse> resetPassword() async {
    if (!validateForm()) {
      return AuthResponse(code: AuthCode.error, message: "Invalid form data");
    }

    AuthResponse response = await authService.resetPassword(password);
    if (response.code == AuthCode.error) {
      showSnackbar(response.message!, AnimatedSnackBarType.error);
      return response;
    }

    return response;
  }

  Future<AuthResponse> forgetPassword() async {
    if (!validateForm()) {
      return AuthResponse(code: AuthCode.error, message: "Invalid form data");
    }

    AuthResponse response = await authService.sendPasswordReset(
      email,
      redirectTo: "${Routes.passwordReset}?resetPassword=true",
    );

    if (response.code == AuthCode.error) {
      
      return response;
    }

    return response;
  }
}
