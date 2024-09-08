import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/providers/choicechipprovider.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormFieldSearchableDropDownField extends ConsumerStatefulWidget {
  const FormFieldSearchableDropDownField({
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

  static Widget defaultFieldBuilder({required Widget child}) {
    return FormFieldWrapperDesignWidget(child: child);
  }

  @override
  ConsumerState<FormFieldSearchableDropDownField> createState() =>
      _FormFieldSearchableDropDownFieldState();
}

class _FormFieldSearchableDropDownFieldState
    extends ConsumerState<FormFieldSearchableDropDownField> {
  final TextEditingController textEditingController = TextEditingController();
  final multiValueListenable = ValueNotifier<List<String>>([]);

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chipValues = ref.watch(
        choiceChipNotifierProvider("${widget.formId}${widget.field.id}"));
    debugPrint(chipValues.toString());

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: widget.width ??
            (constraints.maxWidth < double.infinity && widget.expanded
                ? constraints.maxWidth
                : null),
        height: widget.height ??
            (constraints.maxHeight < double.infinity && widget.expanded
                ? constraints.maxHeight
                : null),
        constraints: widget.maxHeight != null
            ? BoxConstraints(maxHeight: widget.maxHeight!)
            : null,
        child: widget.fieldBuilder!(
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              hint: Text(
                widget.multiSelect ? 'Select Items' : 'Select Item',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                ),
              ),
              items: widget.field.options.map((option) {
                return DropdownItem<String>(
                  value: option.value,
                  child: Text(option.name),
                );
              }).toList(),
              selectedItemBuilder: (context) {
                return chipValues.map((option) {
                  return Text(
                    option.id,
                    style: const TextStyle(
                      fontSize: 14,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  );
                }).toList();
              },
              dropdownStyleData: const DropdownStyleData(
                maxHeight: 200,
              ),
              dropdownSearchData: DropdownSearchData(
                searchController: textEditingController,
                searchBarWidgetHeight: 50,
                noResultsWidget: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('No Item Found!'),
                ),
                searchMatchFn: (item, searchValue) {
                  final fieldName = widget.field.options
                      .firstWhere((x) => x.value == item.value);

                  return fieldName.name
                      .toLowerCase()
                      .contains(searchValue.toLowerCase());
                },
                searchBarWidget: SizedBox(
                  height: 50,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      canRequestFocus: true,
                      controller: textEditingController,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        hintText: 'Search...',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              multiValueListenable: multiValueListenable,
              onChanged: (String? value) {
                final selectedValues = ref.read(choiceChipNotifierProvider(
                        "${widget.formId}${widget.field.id}")
                    .notifier);
                if (chipValues.any((e) => e.id == value)) {
                  if (widget.multiSelect) {
                    selectedValues.removeChoice(value!);
                  } else {
                    selectedValues
                        .addChoice(ChoiceChipValue(id: value!, value: true));
                  }
                } else {
                  selectedValues
                      .replaceChoice(ChoiceChipValue(id: value!, value: true));
                }
              },
              buttonStyleData: const ButtonStyleData(
                padding: EdgeInsets.only(left: 16, right: 8),
                height: 40,
                width: 140,
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.zero,
              ),
              onMenuStateChange: (isOpen) {
                if (!isOpen) {
                  textEditingController.clear();
                }
              },
            ),
          ),
        ),
      );
    });
  }
}
