import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:auto_route/auto_route.dart';
import 'package:extensions_plus/extensions_plus.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthResponse;
import 'package:yourfit/src/models/auth/auth_response.dart';
import 'package:yourfit/src/utils/index.dart';
import 'package:yourfit/src/routing/index.dart';
import 'package:yourfit/src/widgets/index.dart';
import 'package:rxget/rxget.dart';

@RoutePage()
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_SignInController(), tag: 'sign-in');
    return Scaffold(
      body: AuthForm(
        formKey: controller.formKey,
        spacing: 15,
        oauthButtons: [
          OAuthButton(
            icon: AppIcons.googleIcon,
            onPressed: () async =>
                controller.signIn(provider: OAuthProvider.google),
          ),
        ],
        fields: [
          AuthFormTextField(
            labelText: "Email",
            onChanged: (value) => controller.email = value,
            validator: FormBuilderValidators.required<String>(
              errorText: "Email is required",
            ).and(FormBuilderValidators.email(errorText: "Invalid email")),
          ),
          AuthFormTextField(
            labelText: "Password",
            isPassword: true,
            onChanged: (value) => controller.password = value,
            validator:
                FormBuilderValidators.required(
                  errorText: "Password is required",
                ).and(
                  FormBuilderValidators.minLength(
                    6,
                    errorText: "Password must be at least 6 characters long",
                  ),
                ),
            leading: TextButton(
              onPressed: () => context.router.pushPath(Routes.passwordReset),
              style: const ButtonStyle(
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
              ),
              child: Text(
                "Forgot?",
                style: TextStyle(color: Colors.grey[300], fontSize: 16.2),
              ),
            ),
          ),
        ],
        submitButtonChild: const Text(
          "Sign In",
          style: TextStyle(color: Colors.white),
        ),
        onSubmitPressed: () async => await controller.signIn(),
        onBottomButtonPressed: () => context.router.pushPath(Routes.welcome),
      ).center(),
    );
  }
}

class _SignInController extends AuthFormController {
  final AppRouter router = Get.find<AppRouter>();
  final Logger logger = Get.find<Logger>();
  
  Future<void> signIn({OAuthProvider? provider}) async {
    try {
      if (provider != null) {
        AuthResponse response = await signInWithOAuth(provider);
        if (response.code == AuthCode.error) {
          showSnackbar(response.message!, AnimatedSnackBarType.error);
          return;
        }

        router.replacePath(Routes.main);
        return;
      }

      if (!validateForm()) return;
      AuthResponse response = await authService.signInWithPassword(
        email,
        password,
      );

      if (response.code == AuthCode.error) {
       logger.severe("Error signing in: ${response.message}");
        showSnackbar(response.message!, AnimatedSnackBarType.error);
        return;
      }

      router.replacePath(Routes.main);
    } catch (e) {
      logger.severe("Error signing in", e);
      showSnackbar(e.toString(), AnimatedSnackBarType.error);
    }
  }
}
