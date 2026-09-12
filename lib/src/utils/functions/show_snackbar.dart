import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:material_ui/material_ui.dart';

void showSnackbar(
  BuildContext context,
  String message,
  AnimatedSnackBarType type, {
  Duration duration = const Duration(seconds: 3),
}) {
  return AnimatedSnackBar.material(
    message,
    type: type,
    duration: duration,
  ).show(context);
}
