import 'package:material_ui/material_ui.dart';

import 'async_animated_button.dart';

class OAuthButton extends StatelessWidget {
  final Widget icon;
  final Future Function()? onPressed;
  final Text? label;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color foregroundColor;
  final Color backgroundColor;

  const OAuthButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.width = 130,
    this.height = 40,
    this.borderRadius = 20,
    this.foregroundColor = Colors.white,
    this.backgroundColor = Colors.black12,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncAnimatedButton(
      animate: true,
      vibrate: true,
      isThreeD: true,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      foregroundColor: foregroundColor,
      width: width,
      height: height,
      showLoadingIndicator: true,
      loadingIndicatorColor: Colors.grey,
      onPressed: onPressed,
      child: Row(spacing: 10, children: [icon, if (label != null) label!]),
    );
  }
}
