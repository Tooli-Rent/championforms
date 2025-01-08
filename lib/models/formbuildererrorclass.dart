class FormBuilderError {
  final String reason;
  final String fieldId;
  final int validatorPosition;

  const FormBuilderError({
    required this.reason,
    required this.fieldId,
    required this.validatorPosition,
  });
}
