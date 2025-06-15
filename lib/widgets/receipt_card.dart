import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/models/receipt.dart';
import 'package:receipt_scanner_flutter/models/category.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/widgets/modern_card.dart';
import 'package:receipt_scanner_flutter/utils/currency_formatter.dart';
import 'package:receipt_scanner_flutter/utils/date_formatter.dart';

class ReceiptCard extends StatefulWidget {
  final Receipt receipt;
  final VoidCallback? onTap;

  const ReceiptCard({
    super.key,
    required this.receipt,
    this.onTap,
  });

  @override
  State<ReceiptCard> createState() => _ReceiptCardState();
}

class _ReceiptCardState extends State<ReceiptCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final categories = CategoryService.getDefaultCategories();
    final category = categories.firstWhere(
      (cat) => cat.id == widget.receipt.category,
      orElse: () => Category(
        id: 'other',
        name: 'Other',
        icon: '📄',
        color: Colors.grey,
      ),
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ModernCard(
            onTap: () {
              _controller.forward().then((_) {
                _controller.reverse();
                widget.onTap?.call();
              });
            },
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        category.color,
                        category.color.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: category.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      category.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacingM),
                
                // Receipt Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.receipt.company,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: AppTheme.spacingXS),
                          Text(
                            DateFormatter.format(widget.receipt.date),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: AppTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: category.color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          category.name,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: category.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Amount and Arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(widget.receipt.totalAmount),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingXS),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}