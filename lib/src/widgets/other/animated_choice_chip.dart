import 'package:material_ui/material_ui.dart';
import 'package:yourfit/src/widgets/buttons/animated_button.dart';

class AnimatedChoiceChip extends StatelessWidget {
  final Widget? avatar;
  final String labelText;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry? labelPadding;
  final ValueChanged<bool>? onSelected;
  final bool selected;
  final Color? selectedColor;
  final Color? selectedLabelColor;
  final Color? labelColor;
  final Widget? label;
  final String? tooltip;
  final BorderSide? side;
  final OutlinedBorder? shape;
  final Clip clipBehavior;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final Color? shadowColor;
  final Color? selectedShadowColor;
  final ShapeBorder avatarBorder;
  final IconThemeData? iconTheme;
  final BoxConstraints? avatarBoxConstraints;

  const AnimatedChoiceChip({
    super.key,
    this.avatar,
    this.label,
    required this.labelText,
    this.labelStyle,
    this.labelPadding,
    this.onSelected,
    required this.selected,
    this.selectedColor,
    this.tooltip,
    this.side,
    this.shape,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    this.backgroundColor,
    this.padding,
    this.shadowColor,
    this.iconTheme,
    this.selectedShadowColor,
    this.avatarBorder = const CircleBorder(),
    this.avatarBoxConstraints,
    this.selectedLabelColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget =
        label ??
        Text(
          labelText,
          style:
              labelStyle ??
              TextStyle(
                color:
                    (selected
                        ? selectedLabelColor ?? selectedColor
                        : labelColor) ??
                    Colors.black,
              ),
        );

    Widget child = AnimatedButton(
      width: 350,
      onPressed: () => onSelected != null ? onSelected!(!selected) : null,
      backgroundColor: selected ? selectedColor : backgroundColor,
      shadowColor: selected ? selectedShadowColor : shadowColor,
      borderRadius: 10,
      child: Row(
        children: [
          avatar ?? const SizedBox.shrink(),
          padding != null
              ? Padding(padding: padding!, child: labelWidget)
              : labelWidget,
        ],
      ),
    );
    if (padding != null) {
      child = Padding(padding: padding!, child: child);
    }
    return child;
  }
}
