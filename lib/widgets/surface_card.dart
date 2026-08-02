import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/layout_insets.dart';

enum SurfaceCardElevation { home, nested }

/// Standard app surface card — Home cockpit chrome by default.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.border,
    this.color,
    this.elevation = SurfaceCardElevation.home,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final Color? color;
  final SurfaceCardElevation elevation;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? kCardRadius;
    final List<BoxShadow> shadows;
    switch (elevation) {
      case SurfaceCardElevation.home:
        shadows = [
          BoxShadow(
            color: context.colors.textLight.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
      case SurfaceCardElevation.nested:
        shadows = [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];
    }

    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.colors.card,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}
