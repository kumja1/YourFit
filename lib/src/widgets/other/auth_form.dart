import 'package:extensions_plus/extensions_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthResponse;
import 'package:text_divider/text_divider.dart';
import 'package:yourfit/src/models/auth/auth_response.dart';
import 'package:yourfit/src/services/auth_service.dart';
import 'package:yourfit/src/utils/index.dart';
import 'package:yourfit/src/widgets/buttons/animated_button.dart';
import 'package:yourfit/src/widgets/buttons/async_animated_button.dart';
import 'package:zenify/controllers/zen_controller.dart';
import 'package:zenify/di/zen_di.dart';

class AuthForm extends StatelessWidget {
  final List<Widget>? oauthButtons;
  final List<Widget>? fields;
  final double spacing;
  final Key? formKey;

  final Color? submitButtonForegroundColor;
  final Color? submitButtonBackgroundColor;
  final Future Function()? onSubmitPressed;
  final Function()? onBottomButtonPressed;
  final EdgeInsets? submitButtonPadding;
  final Widget? submitButtonChild;
  final Widget? bottomButtonChild;
  final Widget? title;

  final bool showTitle;
  final bool showFields;
  final bool showBottomButton;
  final bool showSubmitButton;
  final bool showOAuth;

  const AuthForm({
    super.key,
    this.formKey,
    this.onSubmitPressed,
    this.submitButtonChild,
    this.showFields = true,
    this.showBottomButton = true,
    this.showSubmitButton = true,
    this.showTitle = true,
    this.showOAuth = true,
    this.spacing = 10,
    this.submitButtonPadding,
    this.onBottomButtonPressed,
    this.fields,
    this.title,
    this.submitButtonBackgroundColor,
    this.submitButtonForegroundColor,
    this.oauthButtons,
    this.bottomButtonChild,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showTitle && title != null) title!,
            if (showOAuth && oauthButtons != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: oauthButtons!,
              ),
              const SizedBox(
                width: 420,
                child: TextDivider(
                  text: Text(
                    "OR",
                    style: TextStyle(color: Colors.black12),
                    textAlign: TextAlign.center,
                  ),
                  color: Colors.black12,
                ),
              ).paddingSymmetric(vertical: 20),
            ],
            if (showFields && fields != null)
              FormBuilder(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUnfocus,
                child: Column(spacing: spacing, children: fields!),
              ),

            if (showSubmitButton && submitButtonChild != null) ...[
              Padding(
                padding:
                    submitButtonPadding ??
                    const EdgeInsets.symmetric(vertical: 20),
                child: AsyncAnimatedButton(
                  backgroundColor:
                      submitButtonBackgroundColor ?? Colors.blueAccent,
                  foregroundColor: submitButtonForegroundColor ?? Colors.blue,
                  showLoadingIndicator: true,
                  borderRadius: 50,
                  onPressed: onSubmitPressed,
                  child: submitButtonChild!,
                ),
              ),
            ],
          ],
        ),
        if (showBottomButton) ...[
          Positioned.fill(
            child: AnimatedButton(
              width: 250,
              height: 40,
              shadowColor: Colors.black12,
              backgroundColor: Colors.white,
              borderRadius: 50,
              onPressed: onBottomButtonPressed,
              child:
                  bottomButtonChild ??
                  const Text(
                    "New User? Create an Account",
                    style: TextStyle(color: Colors.black12),
                  ),
            ).paddingOnly(bottom: 10),
          ),
        ],
      ],
    );
  }
}

class AuthFormController extends ZenController {
  final GlobalKey<FormBuilderState> formKey = GlobalKey();
  final AuthService authService = Zen.find<AuthService>();

  Rx<String> email = ''.obs();
  Rx<String> password = ''.obs();

  Future<AuthResponse> signInWithOAuth(OAuthProvider provider) async {
    AuthResponse response = await authService.signInWithOAuth(provider);

    await Future.doWhile(() => !authService.isSignedIn);
    return response;
  }

  bool validateForm() {
    if (formKey.currentState == null) {
      return false;
    }

    return formKey.currentState!.saveAndValidate();
  }
}
