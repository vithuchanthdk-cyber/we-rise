import 'package:flutter/material.dart';

enum WeRiseButtonStyle { filled, outlined, text, destructive }

class WeRiseButton extends StatelessWidget {
  const WeRiseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = WeRiseButtonStyle.filled,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final WeRiseButtonStyle style;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: style == WeRiseButtonStyle.filled
                  ? colorScheme.onPrimary
                  : colorScheme.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
              Text(label),
            ],
          );

    if (fullWidth) {
      child = SizedBox(width: double.infinity, child: child);
    }

    final Widget button = switch (style) {
      WeRiseButtonStyle.filled => FilledButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      WeRiseButtonStyle.outlined => OutlinedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      WeRiseButtonStyle.text => TextButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      WeRiseButtonStyle.destructive => FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: child,
        ),
    };

    return Semantics(
      button: true,
      enabled: !loading && onPressed != null,
      label: label,
      child: button,
    );
  }
}
