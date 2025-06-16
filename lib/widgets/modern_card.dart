import 'package:flutter/material.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool elevated;
  final Color? backgroundColor;
  final List<BoxShadow>? customShadow;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevated = false,
    this.backgroundColor,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cardWidget = Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? const Color(0xFF1F2937) : AppTheme.cardColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: customShadow ?? (elevated ? AppTheme.elevatedShadow : AppTheme.cardShadow),
        border: isDark ? Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ) : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}