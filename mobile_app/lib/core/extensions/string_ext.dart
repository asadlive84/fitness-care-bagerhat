/// String extensions for common text transformations.
extension StringExt on String {
  /// Capitalizes the first letter of the string.
  ///
  /// Example: "hello" → "Hello"
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns the initials from a name (up to 2 characters).
  ///
  /// Examples:
  /// - "Karim Ahmed" → "KA"
  /// - "Rahim" → "R"
  /// - "" → "?"
  String get initials {
    if (trim().isEmpty) return '?';
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Masks a phone number for privacy.
  ///
  /// Example: "01711000001" → "0171***0001"
  String get maskedPhone {
    if (length < 7) return this;
    return '${substring(0, 4)}***${substring(length - 4)}';
  }

  /// Returns true if the string looks like a valid email.
  bool get isValidEmail => RegExp(r'^[\w\-.]+@[\w\-.]+\.\w+$').hasMatch(this);

  /// Returns true if the string looks like a valid BD phone number.
  bool get isValidBDPhone =>
      RegExp(r'^01[3-9]\d{8}$').hasMatch(replaceAll('-', ''));
}
