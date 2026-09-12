import 'package:extensions_plus/extensions_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class NumberFormField<T extends num> extends StatelessWidget {
  final Function(T value)? onChanged;
  final FormFieldValidator<dynamic>? validator;
  final Function(T value)? onSaved;
  final String labelText;
  final T? initialValue;
  final List<TextInputFormatter>? inputFormatters;
  final double? width;
  final double? height;

  final String name;

  const NumberFormField({
    super.key,
    required this.name,
    required this.labelText,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.inputFormatters,
    this.width = 360,
    this.height,
    this.onSaved,
    
  });

  @override
  Widget build(BuildContext context) =>
      FormBuilderTextField(
        name: name,
        keyboardType: TextInputType.number,
        inputFormatters: inputFormatters,
        initialValue: initialValue?.toString(),
        decoration: InputDecoration(
          labelText: labelText,
        ),
        onChanged: (s) {
          if (onChanged == null || s == null) return;
          onChanged!(num.parse(s) as T);
        },
        valueTransformer: (s) => num.parse(s ?? "0") as T,
        validator: validator == null
            ? FormBuilderValidators.numeric()
            : FormBuilderValidators.numeric().and(validator!),
      ).constrains(
        maxWidth: width ?? double.infinity,
        maxHeight: height ?? double.infinity,
      );
}
