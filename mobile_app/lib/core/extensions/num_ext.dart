import 'package:intl/intl.dart';

/// Numeric extensions for currency and unit formatting.
///
/// Currency is always displayed as `৳ 1,500` (BDT with comma grouping).
extension NumExt on num {
  /// Formats as BDT currency: `৳ 1,500`
  ///
  /// Uses comma grouping and no decimal places for whole numbers.
  String toBDT() {
    final formatter = NumberFormat('#,##0', 'en_US');
    if (this == toInt()) {
      return '৳ ${formatter.format(toInt())}';
    }
    return '৳ ${NumberFormat('#,##0.00', 'en_US').format(this)}';
  }

  /// Formats as weight in kilograms: `72.5 kg`
  String toKg() {
    if (this == toInt()) {
      return '${toInt()} kg';
    }
    return '${toStringAsFixed(1)} kg';
  }

  /// Formats as compact number: 1K, 2.5M, etc.
  String toCompact() => NumberFormat.compact().format(this);

  /// Formats with comma grouping: 1,234,567
  String toFormatted() => NumberFormat('#,##0').format(this);
}
