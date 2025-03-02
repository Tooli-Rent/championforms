import 'package:championforms/championforms.dart';
import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:collection/collection.dart';

class FieldResults {
  final String id;
  final List<FieldResultData> values;
  final FieldType type;

  const FieldResults({
    required this.id,
    required this.values,
    required this.type,
  });

  // As String -- join all values together into one long string, take in an optional seperator if desired or fall back to ", "

  // Optional result id
  String asString({String? id, String delimiter = ", ", String fallback = ""}) {
    String output = "";
    if (type == FieldType.bool) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        output = item?.active ?? false ? item?.value ?? "" : "";
      } else {
        // We're going to merge this all together into one long string of values
        output = values.map((item) => item.value).join(delimiter);
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        output = item?.value ?? "";
      } else {
        // We're going to merge this all together into one long string of values
        output = values.map((item) => item.value).join(delimiter);
      }
    }
    return output != "" ? output : fallback;
  }

  List<String> asStringList({String? id, List<String> fallback = const []}) {
    List<String> output = [];
    if (type == FieldType.bool) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        output.add(item?.active ?? false ? item?.id ?? "" : "");
      } else {
        // We're going to merge this all together into one long string of values
        output.addAll(values.map((item) => item.id).toList());
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        output.add(item?.value ?? "");
      } else {
        // We're going to merge this all together into one long string of values
        output.addAll(values.map((item) => item.value ?? "").toList());
      }
    }
    return output != [] ? output : fallback;
  }

  // As Bool -- True or false. returns a list of true / false values

  List<bool> asBool({String? id}) {
    if (type == FieldType.bool) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        if (item == null) return [false];
        return [item.active];
      } else {
        // We're going to merge this all together into one long string of values
        return values.map((item) => item.active).toList();
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        if (item == null) return [false];
        return item.value != "" ? [true] : [false];
      } else {
        // We're going to merge this all together into one long string of values
        return values.map((item) => item.value != "" ? true : false).toList();
      }
    }
    return [];
  }

  // As Named Bool True or false. returns a map of ID / true / false values

  Map<String, bool> asBoolMap({String? id}) {
    if (type == FieldType.bool) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        if (item == null) return {};
        return {item.id: item.active};
      } else {
        // We're going to merge this all together into one long string of values
        Map<String, bool> myMap = {
          for (var item in values) item.id: item.active
        };
        return myMap;
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        if (item == null) return {};
        return {item.value ?? item.id: item.value != "" ? true : false};
      } else {
        // We're going to merge this all together into one long string of values
        Map<String, bool> myMap = {
          for (var item in values)
            item.value ?? item.id: item.value != "" ? true : false
        };
        return myMap;
      }
    }
    return {};
  }

  // As MultiSelect
  MultiselectOption? asMultiselectSingle({String? id}) {
    MultiselectOption? item;
    if (id != null) {
      item = values.firstWhereOrNull((data) => data.id == id)?.optionValue;
    } else {
      item = values.firstOrNull?.optionValue;
    }

    return item;
  }

  // As MultiSelect List
  List<MultiselectOption> asMultiselectList({String? id}) {
    final items = values.map((data) => data.optionValue!).toList();

    return items;
  }
}

enum FieldType {
  string,
  bool,
  parchment,
}

class FieldResultData {
  final FieldType type;
  final String id;
  final String? value;
  final MultiselectOption? optionValue;
  final bool active;
  const FieldResultData({
    this.type = FieldType.string,
    this.id = "noid",
    this.optionValue,
    this.value,
    this.active = false,
  });
}

// We're going to compress the form's fields into an object we can traverse with some handy helper functions for pulling the results out.
class FormResults {
  final bool errorState;
  final List<FormBuilderError> formErrors;
  final List<FieldResults> results;
  // Because this is just a wrapper around calling Riverpod directly we're going to need access to widgetref
  const FormResults({
    this.errorState = false,
    this.formErrors = const [],
    required this.results,
  });

  // This factory pulls in all results and also does some handy error checking on the fields. The finished result can be worked with to find detailed information on each field.
  factory FormResults.getResults({
    required ChampionFormController controller,
    bool checkForErrors = true,
    List<FormFieldDef>? fields,
  }) {
    List<FormFieldDef> finalFields = fields ?? controller.fields;

    // Initialize our results list
    List<FieldResults> results = [];

    // Lets loop through our fields and add them to the results
    for (final field in finalFields) {
      // Loop through each field and we need to gather results and if asked report on field errors.

      // Start by determining the field type so we can properly associate the data to the field.

      FieldType type;
      switch (field) {
        case ChampionTextField():
          type = FieldType.string;
          final value = controller.findTextFieldValue(field.id)?.value ?? "";

          results.add(FieldResults(
            id: field.id,
            values: [FieldResultData(value: value, id: field.id, type: type)],
            type: type,
          ));
          break;
        case ChampionOptionSelect():
          type = FieldType.bool;
          final value = controller.findMultiselectValue(field.id)?.values ?? [];

          results.add(FieldResults(
            id: field.id,
            values: value
                .map((val) => FieldResultData(
                    value: val.value
                        .toString(), // Merge all the options into a comma seperated list
                    optionValue:
                        val, // This is the actual list of values which we can access in our field results.
                    id: field.id,
                    active: true,
                    type: type))
                .toList(),
            type: type,
          ));

          break;

        default:
          type = FieldType.string;
      }
    }
    bool errorState = false;
    List<FormBuilderError> formErrors = [];
    // Check for errors and set the error state
    if (checkForErrors) {
      formErrors.addAll(
          getFormBuilderErrors(results: results, controller: controller));
      if (formErrors.isNotEmpty) {
        errorState = true;
      }
    }
    return FormResults(
      formErrors: formErrors,
      errorState: errorState,
      results: results,
    );
  }

  // Grab field value (or with default)
  FieldResults grab(String id) {
    return results.firstWhere((item) => item.id == id);
  }

  // Grab field list value (or with default)

  // Grab value or null

  // Grab list or null

  // execute error check
}
