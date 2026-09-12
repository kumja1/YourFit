import 'package:custom_button_builder/custom_button_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yourfit/src/utils/index.dart';

class AsyncAnimatedButton extends StatelessWidget {
  final Future Function()? onPressed;
  final Widget child;
  final bool disabled;
  final bool showLoadingIndicator;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool animate;
  final bool vibrate;
  final bool isThreeD;
  final Color loadingIndicatorColor;
  final Color? foregroundColor;
  final Color? backgroundColor;

  final String _tag = UniqueKey().toString();

  AsyncAnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.showLoadingIndicator = true,
    this.disabled = false,
    this.width = 250,
    this.height = 40,
    this.borderRadius = 20,
    this.animate = true,
    this.vibrate = true,
    this.isThreeD = true,
    this.foregroundColor,
    this.backgroundColor,
    this.loadingIndicatorColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      _AsyncAnimatedButtonController(),
      tag: _tag,
    );
    return CustomButton(
      onPressed: () =>
          controller.handleOnPressed(onPressed, showLoadingIndicator),
      backgroundColor: foregroundColor ?? Colors.blue[600],
      shadowColor: backgroundColor ?? Colors.blue,
      height: height,
      width: width,
      animate: animate,
      isThreeD: isThreeD,
      borderRadius: borderRadius,
      child: Obx(
        () => controller.isLoading.value
            ? CircularProgressIndicator(color: loadingIndicatorColor)
            : child,
      ),
    );
  }
}

class _AsyncAnimatedButtonController {
  final isLoading = false.obs;

  Future<void> handleOnPressed(
    Future Function()? onPressed,
    bool loadingAnimation,
  ) async {
    if (onPressed == null) return;

    if (loadingAnimation) {
      try {
        isLoading.value = true;
        await onPressed();
      } finally {
        isLoading.value = false;
      }
    } else {
      await onPressed();
    }
  }
}
