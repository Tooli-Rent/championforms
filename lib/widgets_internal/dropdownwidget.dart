import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/providers/choicechipprovider.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

class FormFieldDropDownField extends ConsumerWidget {
  const FormFieldDropDownField({
    super.key,
    required this.field,
    required this.formId,
    this.multiSelect = true,
    this.width,
    this.height,
    this.maxHeight,
    this.expanded = false,
    Widget Function({required Widget child})? fieldBuilder,
  }) : fieldBuilder = fieldBuilder ?? defaultFieldBuilder;

  final FormFieldDef field;
  final Widget Function({required Widget child})? fieldBuilder;
  final String formId;
  final bool multiSelect;
  final double? width;
  final double? height;
  final double? maxHeight;
  final bool expanded;

  // Default implementation for the fieldBuilder.
  static Widget defaultFieldBuilder({required Widget child}) {
    // Replace this with the implementation of `FormFieldWrapperDesignWidget`.
    return FormFieldWrapperDesignWidget(child: child);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chipValues =
        ref.watch(choiceChipNotifierProvider("$formId${field.id}"));

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: width ??
            (constraints.maxWidth < double.infinity && expanded
                ? constraints.maxWidth
                : null),
        height: height ??
            (constraints.maxHeight < double.infinity && expanded
                ? constraints.maxHeight
                : null),
        constraints:
            maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
        child: fieldBuilder!(
          child: DropdownButtonFormField<String>(
            value: chipValues.isNotEmpty ? chipValues.first.id : null,
            items: field.options
                .map((option) => DropdownMenuItem<String>(
                      value: option.value,
                      child: Text(option.name),
                    ))
                .toList(),
            onChanged: (String? value) {
              if (value != null) {
                ref
                    .read(choiceChipNotifierProvider("$formId${field.id}")
                        .notifier)
                    .addChoice(ChoiceChipValue(id: value, value: true));
              }
            },
          ),
        ),
      );
    });
  }
}
