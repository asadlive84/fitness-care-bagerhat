import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:flutter/material.dart';

/// ## GymAvatar
///
/// Circular avatar showing initials with a deterministic background color.
///
/// The color is computed from a hash of the name so each member always
/// gets the same color. Supports small (32), medium (48), and large (80) sizes.
///
/// ### Usage
/// ```dart
/// GymAvatar(name: 'Karim Ahmed', size: 48)
/// ```
class GymAvatar extends StatelessWidget {
  const GymAvatar({
    required this.name,
    super.key,
    this.size = 48,
    this.imageUrl,
  });

  /// The person's full name (used for initials and color).
  final String name;

  /// Diameter in logical pixels.
  final double size;

  /// Optional network image URL.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final color = _colorFromName(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: imageUrl != null
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialsWidget(
                  initials: initials,
                  size: size,
                ),
              ),
            )
          : _InitialsWidget(initials: initials, size: size),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Deterministic color from name hash — 12 hue options.
  static Color _colorFromName(String name) {
    const palette = [
      Color(0xFF1B5E20), // green
      Color(0xFF0D47A1), // blue
      Color(0xFFBF360C), // deep orange
      Color(0xFF4A148C), // purple
      Color(0xFF006064), // teal
      Color(0xFF880E4F), // pink
      Color(0xFF33691E), // light green
      Color(0xFF1A237E), // indigo
      Color(0xFFE65100), // orange
      Color(0xFF004D40), // dark teal
      Color(0xFF311B92), // deep purple
      Color(0xFF827717), // lime
    ];

    var hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return palette[hash.abs() % palette.length];
  }
}

class _InitialsWidget extends StatelessWidget {
  const _InitialsWidget({required this.initials, required this.size});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: AppText.labelLarge.copyWith(
          color: AppColors.textOnDark,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
