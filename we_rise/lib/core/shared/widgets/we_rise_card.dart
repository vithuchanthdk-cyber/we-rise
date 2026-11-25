import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WeRiseCard extends StatelessWidget {
  const WeRiseCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.highlighted = false,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(AppRadius.md),
        side: highlighted
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(AppRadius.md),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}
