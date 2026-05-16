import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// ## GymShimmer
///
/// Skeleton loader variants to match real content shapes.
class GymShimmer extends StatelessWidget {
  const GymShimmer({
    required this.width,
    required this.height,
    super.key,
    this.borderRadius = AppSpacing.r8,
  });

  /// Base shimmer for a rectangular shape.
  const GymShimmer.card({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = AppSpacing.r16,
  });

  /// Shimmer for a circular avatar.
  const GymShimmer.avatar({
    required double size,
    super.key,
  })  : width = size,
        height = size,
        borderRadius = AppSpacing.rFull;

  /// Shimmer for a text line.
  const GymShimmer.line({
    this.width = 150,
    this.height = 16,
    super.key,
  })  : borderRadius = AppSpacing.r4;

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white10 : Colors.grey.shade200,
      highlightColor: isDark ? Colors.white24 : Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
