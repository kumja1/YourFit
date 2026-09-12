import 'package:extensions_plus/extensions_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:yourfit/src/utils/index.dart';

class AuthFormTextField extends StatelessWidget {
  final Function(String value)? onChanged;
  final String labelText;
  final TextStyle? labelStyle;
  final TextStyle? floatingLabelStyle;
  final bool isPassword;
  final Color passwordVisibilityColor;
  final String? Function(String? value)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final double? width;
  final double? height;
  final Widget? leading;

  const AuthFormTextField({
    super.key,
    required this.labelText,
    this.onChanged,
    this.validator,
    this.inputFormatters,
    this.keyboardType,
    this.isPassword = false,
    this.passwordVisibilityColor = Colors.blue,
    this.width = 360,
    this.height,
    this.leading,
    this.labelStyle = const TextStyle(color: Colors.black12),
    this.floatingLabelStyle = const TextStyle(color: Colors.blue),
  });

  @override
  Widget build(BuildContext context) {
    final tag = '${key ?? identityHashCode(this)}';
    final controller = Get.put(
      _AuthFormTextFieldController(),
      tag: tag,
    );
    return Obx(
      () => TextFormField(
          obscureText: !controller.passwordVisible.value,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            suffixIcon: !isPassword
                ? null
                : leading ??
                      IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => controller.togglePasswordVisibility(),
                        icon: Icon(
                          controller.passwordVisible.value
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: passwordVisibilityColor,
                        ),
                      ),
            labelText: labelText,
            labelStyle: WidgetStateTextStyle.resolveWith(
              (state) => state.contains(WidgetState.error)
                  ? const TextStyle(color: Colors.red)
                  : labelStyle!,
            ),
            floatingLabelStyle: WidgetStateTextStyle.resolveWith(
              (state) => state.contains(WidgetState.error)
                  ? const TextStyle(color: Colors.red)
                  : floatingLabelStyle!,
            ),
          ),
      ),
    ).constrains(
        maxWidth: width ?? double.infinity,
        maxHeight: height ?? double.infinity,
      );
  }
}

class _AuthFormTextFieldController {
  final Rx<bool> passwordVisible = false.obs;

  void togglePasswordVisibility() {
    passwordVisible.value = !passwordVisible.value;
  }
}
