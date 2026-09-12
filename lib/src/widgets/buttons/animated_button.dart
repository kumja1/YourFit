import 'package:custom_button_builder/custom_button_builder.dart';
import 'package:material_ui/material_ui.dart';

class AnimatedButton extends StatelessWidget {
  // this can be used to give a title to the widget
  final String? title;

  // the name suggest that you can add a textWidget but it can be anything
  final Widget? child;

  // this can be used to give a custom gradient to the button
  final Gradient? gradient;

  // this is the background color of the button which does not include the shadow color
  final Color? backgroundColor;

  // this can be used to give a custom shadow to the button
  final List<BoxShadow>? boxShadow;

  final Decoration? decoration;

  final Widget? iconWidget; // Icon(Icons.abc)
  final ButtonAsset?
  asset; // can be an Svg or an Image asset, you can optionally also pass in the height and width and color as well

  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;

  // this is used to color the shadow of the button
  final Color? shadowColor;
  final Widget? subtitle;

  /// this can be used to pass in the value is the button is loading then circular progress will be shown
  final bool isLoading;

  // using this we can set the button property to vibrate or to not vibrate
  final bool vibrate;

  final List<Widget>? rowChildren;

  // reversing the position of the icon and the text
  final bool reversePosition;

  // this is the onpressed function that is executed when the button is pressed
  final void Function()? onPressed;

  /// this is the value of the button when the animate property is set to true and isThree is also true then
  /// using this value we can have the disabled button effect where the button is pressed inside using the Pressed.pressed value
  /// and using the default value Pressed.notPressed the button can be restored to 3d version

  final Pressed pressed;

  // if you want to change the crossAxis value of the column when you give a subtitle
  //and title to the button then this can be used
  final CrossAxisAlignment crossAxis;

  /// width of the button
  final double? width;

  /// height of the button when the button's animate property is set to true then the user has to give a height value to the button
  /// or the button will not work
  final double? height;

  /// used to give the mainAxis value to the row
  final MainAxisAlignment mainAxis;

  const AnimatedButton({
    super.key,
    this.pressed = Pressed.notPressed,
    this.vibrate = true,
    this.shadowColor,
    this.crossAxis = CrossAxisAlignment.start,
    this.subtitle,
    this.rowChildren,
    this.mainAxis = MainAxisAlignment.center,
    this.width = 250,
    this.height = 40,
    required this.onPressed,
    this.reversePosition = false,
    this.title,
    this.child,
    this.gradient,
    this.backgroundColor = Colors.blue,
    this.iconWidget,
    this.asset,
    this.boxShadow,
    this.margin,
    this.padding,
    this.borderRadius = 50,
    this.decoration,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => CustomButton(
    animate: true,
    isThreeD: true,
    onPressed: onPressed,
    backgroundColor: backgroundColor,
    padding: padding,
    borderRadius: borderRadius,
    shadowColor: shadowColor ?? Colors.blue[600],
    width: width,
    height: height,
    decoration: decoration,
    asset: asset,
    boxShadow: boxShadow,
    crossAxis: crossAxis,
    gradient: gradient,
    iconWidget: iconWidget,
    isLoading: isLoading,
    mainAxis: mainAxis,
    margin: margin,
    pressed: pressed,
    reversePosition: reversePosition,
    rowChildren: rowChildren,
    subtitle: subtitle,
    title: title,
    vibrate: vibrate,
    child: child,
  );
}
