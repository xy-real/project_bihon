class ContactValidation {
  const ContactValidation._();

  static const List<String> allowedTypes = [
    'Family',
    'Barangay Official',
    'Rescue Team',
    'Hospital',
    'Other',
  ];

  static String normalizeName(String value) {
    return value.trim();
  }

  static bool isValidName(String value) {
    final normalized = normalizeName(value);
    final visibleLength = normalized.replaceAll(RegExp(r'\s+'), '').length;
    return visibleLength >= 2;
  }

  static String normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  static bool isValidPhone(String value) {
    final normalized = normalizePhone(value);
    final localPattern = RegExp(r'^09\d{9}$');
    final intlPattern = RegExp(r'^\+63\d{10}$');
    return localPattern.hasMatch(normalized) || intlPattern.hasMatch(normalized);
  }

  static bool isAllowedType(String value) {
    return allowedTypes.contains(value.trim());
  }
}
