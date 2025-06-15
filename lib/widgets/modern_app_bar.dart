import 'package:flutter/material.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const ModernAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          child: Row(
            children: [
              if (showBackButton || leading != null) ...[
                leading ?? IconButton(
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceColor,
                    foregroundColor: AppTheme.textPrimary,
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    minimumSize: const Size(40, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: AppTheme.spacingM),
                ...actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}