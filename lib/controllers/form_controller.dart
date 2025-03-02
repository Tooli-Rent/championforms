// We are going to build one giant controller to handle all aspects of our form.

import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formcontroller/field_focus.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formvalues/multiselect_form_field_value_by_id.dart';
import 'package:championforms/models/formvalues/text_form_field_value_by_id.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

class ChampionFormController extends ChangeNotifier {
  // field ID. This differentiates this field from other fields.
  final String id;

  // Link Fields to this controller
  List<FormFieldDef> fields;

  // Handle text field default values
  List<TextFormFieldValueById> textFieldValues;

  // Handle multiselect field default values
  List<MultiselectFormFieldValueById> multiselectValues;

  // Handle form focus controllers
  List<FieldFocus> fieldFocus;

  // Form Error Data
  List<FormBuilderError> formErrors;

  ChampionFormController({
    String? id,
    this.fields = const [],
    this.textFieldValues = const [],
    this.multiselectValues = const [],
    this.fieldFocus = const [],
    this.formErrors = const [],
  }) : id = id ?? Uuid().v4();

  // Lets start by managing all the fields this controller is responsible for.
  // This function allows us to connect disparate championform instances together into one controller
  void addFields(List<FormFieldDef> newFields) {
    fields = [...fields, ...newFields];
    notifyListeners();
  }

  // Update text field values
  void updateTextFieldValue(String id, String newValue) {
    final reference = findTextFieldValueIndex(id);
    if (reference != null) {
      textFieldValues[reference] =
          TextFormFieldValueById(id: id, value: newValue);
    } else {
      textFieldValues = [
        TextFormFieldValueById(id: id, value: newValue),
        ...textFieldValues
      ];
    }

    notifyListeners();
  }

  TextFormFieldValueById? findTextFieldValue(String id) {
    final reference = findTextFieldValueIndex(id);
    if (reference != null) {
      return textFieldValues[reference];
    }
    return null;
  }

  int? findTextFieldValueIndex(String id) {
    for (int i = 0; i < textFieldValues.length; i++) {
      if (textFieldValues[i].id == id) {
        return i;
      }
    }
    return null;
  }

  // This is a helper function so you can find the field options and then toggle them via a list of string values.
  void toggleMultiSelectValue(
    String fieldId, {
    List<String> toggleOn = const [],
    List<String> toggleOff = const [],
  }) {
    final field =
        fields.firstWhereOrNull((fieldData) => fieldData.id == fieldId);


    if (field == null || field is! ChampionOptionSelect) {
      debugPrint("Tried to toggle values on a field that doesn't seem to exist: $fieldId");
      return;
    };

    final List<MultiselectOption> selectOptions = field.options
        .where((option) => toggleOn.contains(option.value))
        .toList();

    final List<MultiselectOption> deSelectOptions = field.options
        .where((option) => toggleOn.contains(option.value))
        .toList();
    // Run the logic to add and remove these values
    final reference = findMultiselectValueIndex(id);

    if (reference == null) {
     multiselectValues = [
       MultiselectFormFieldValueById(
         id: field.id,
         values: selectOptions,
       ),
       ...multiselectValues,];
    } else {

    multiselectValues[reference] = MultiselectFormFieldValueById(
        id: multiselectValues[reference].id,
        values: [
          // original values minus the addition and subtracted values
          // Leave original selections intact
          ...multiselectValues[reference].values.where((value) =>
              !selectOptions.any((selected) => selected.value == value.value) &&
              !deSelectOptions
                  .any((deSelected) => deSelected.value == value.value)),

          // The new values we're adding in
          ...selectOptions,
        ]);
    }

    notifyListeners();
  }

  // Update Multiselect values
  void updateMultiselectValues(String id, List<MultiselectOption> newValue,
      {bool multiselect = false}) {
    final reference = findMultiselectValueIndex(id);

    if (reference != null) {
      // Lets do some massaging to the values to see if we need to remove some items based on this list.

      // Lets subtract any values that are already stored, and then add any values which should be added.
      final listToRemove = newValue
          .where((value) => multiselectValues[reference]
              .values
              .any((existingValue) => existingValue.value == value.value))
          .toList();

      final updatedValue = [
        // Any Additional new values minus the ones which we removed.
        ...newValue.where((value) =>
            !listToRemove.any((removeVar) => removeVar.value == value.value)),
        // original values minus the values we should be removing (because they were selected again)
        ...multiselectValues[reference].values.where((value) =>
            !listToRemove.any((removeVar) => removeVar.value == value.value)),
      ];

      multiselectValues[reference] = MultiselectFormFieldValueById(
          id: id,
          values: multiselect
              ? updatedValue
              : updatedValue.isNotEmpty
                  ? [updatedValue.first]
                  : []);
    } else {
      multiselectValues = [
        MultiselectFormFieldValueById(
            id: id,
            values: multiselect
                ? newValue
                : newValue.isNotEmpty
                    ? [newValue.first]
                    : [])
      ];
    }

    notifyListeners();
  }

  void resetMultiselectChoices(String fieldId) {
    final reference = findMultiselectValueIndex(id);
    if (reference != null) {
      multiselectValues.removeAt(reference);
      notifyListeners();
    }
    return;
  }

  MultiselectFormFieldValueById? findMultiselectValue(String id) {
    final reference = findMultiselectValueIndex(id);
    if (reference != null) {
      return multiselectValues[reference];
    }
    return null;
  }

  int? findMultiselectValueIndex(String id) {
    for (int i = 0; i < multiselectValues.length; i++) {
      if (multiselectValues[i].id == id) {
        return i;
      }
    }
    return null;
  }

  // Manage Errors
  List<FormBuilderError> findErrors(String fieldId) {
    return formErrors.where((error) => error.fieldId == fieldId).toList();
  }

  void clearErrors(String fieldId) {
    formErrors = formErrors.where((error) => error.fieldId != fieldId).toList();
    notifyListeners();

    return;
  }

  void clearError(String fieldId, int errorPosition) {
    formErrors = formErrors
        .where((error) => error.validatorPosition != errorPosition)
        .toList();

    notifyListeners();
    return;
  }

  void addError(FormBuilderError error) {
    formErrors = [error, ...formErrors];
    notifyListeners();
  }

  // Lets Handle FocusNodes

  bool isFieldFocused(String fieldId) {
    return fieldFocus.firstWhereOrNull((field) => field.id == fieldId)?.focus ??
        false;
  }

  // Set field focus
  void setFieldFocus(String fieldId, bool focused) {
    final reference = findFieldFocusIndex(fieldId);
    if (reference != null) {
      fieldFocus[reference] = FieldFocus(
        id: fieldId,
        focus: focused,
      );
    } else {
      fieldFocus = [
        FieldFocus(
          id: fieldId,
          focus: focused,
        ),
        ...fieldFocus
      ];
    }
    notifyListeners();
  }

  int? findFieldFocusIndex(String fieldId) {
    for (int i = 0; i < fieldFocus.length; i++) {
      if (fieldFocus[i].id == id) {
        return i;
      }
    }
    return null;
  }
}
