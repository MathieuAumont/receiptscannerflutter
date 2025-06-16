import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/providers/budget_provider.dart';
import 'package:receipt_scanner_flutter/utils/currency_formatter.dart';
import 'package:receipt_scanner_flutter/models/category.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final receiptProvider = Provider.of<ReceiptProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);

    final currentMonthKey = budgetProvider.getCurrentMonthKey();
    final totalBudget = budgetProvider.getTotalBudgetForMonth(currentMonthKey);
    final monthlySpending = receiptProvider.getMonthlySpending();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                languageProvider.translate('receipt_scanner'),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              titlePadding: const EdgeInsets.only(
                left: AppTheme.spacingM,
                bottom: AppTheme.spacingM,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: 'Budget',
                          value: CurrencyFormatter.format(totalBudget),
                          icon: '💰',
                          color: const Color(0xFF10B981),
                          subtitle: 'Ce mois',
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: 'Dépensé',
                          value: CurrencyFormatter.format(monthlySpending),
                          icon: '📊',
                          color: const Color(0xFFF59E0B),
                          subtitle: totalBudget > 0 
                              ? '${((monthlySpending / totalBudget) * 100).toStringAsFixed(0)}%'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Actions rapides
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          title: 'Scanner',
                          icon: '📷',
                          color: const Color(0xFF6366F1),
                          onTap: () => context.go('/scan'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          title: 'Ajouter',
                          icon: '➕',
                          color: const Color(0xFFEC4899),
                          onTap: () => context.go('/manual-entry'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Recent Receipts Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        languageProvider.translate('recent_receipts'),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/reports'),
                        child: Text(languageProvider.translate('see_all')),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingM),
                  
                  // Receipts List
                  if (receiptProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacingXXL),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (receiptProvider.recentReceipts.isEmpty)
                    _buildEmptyState(context, languageProvider)
                  else
                    _buildReceiptsList(receiptProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsList(ReceiptProvider receiptProvider) {
    return Column(
      children: receiptProvider.recentReceipts.map((receipt) {
        return Container(
          key: ValueKey('receipt_${receipt.id}'),
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: _buildSimpleReceiptCard(receipt),
        );
      }).toList(),
    );
  }

  Widget _buildSimpleReceiptCard(receipt) {
    return Builder(
      builder: (context) {
        final categories = CategoryService.getDefaultCategories();
        final category = categories.firstWhere(
          (cat) => cat.id == receipt.category,
          orElse: () => categories.first,
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/receipt/${receipt.id}'),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF1F2937) 
                    : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
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
                    ),
                    child: Center(
                      child: Text(
                        category.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.company,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          '${receipt.date.day}/${receipt.date.month}/${receipt.date.year}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(receipt.totalAmount),
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
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingS,
                  vertical: AppTheme.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required String title,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1F2937) 
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '📄',
              style: TextStyle(fontSize: 48),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            languageProvider.translate('no_receipts'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            languageProvider.translate('no_receipts_subtitle'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/scan'),
                  icon: const Text('📷'),
                  label: const Text('Scanner'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/manual-entry'),
                  icon: const Text('➕'),
                  label: const Text('Ajouter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}