import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/svg.dart';

class AppIcons {
  static final googleIcon = const SvgPicture(
    SvgAssetLoader("assets/icons/auth/google.svg"),
    width: 29,
    height: 29,
  );

  static final intensityIcon = const ImageIcon(
    AssetImage("assets/icons/intensity.png"),
  );

  static final calorieIcon = const ImageIcon(AssetImage("assets/icons/calorie.png"));
}
