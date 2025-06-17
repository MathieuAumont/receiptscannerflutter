import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/providers/budget_provider.dart';
import 'package:receipt_scanner_flutter/utils/currency_formatter.dart';
import 'package:receipt_scanner_flutter/models/category.dart';
import 'package:receipt_scanner_flutter/models/receipt.dart';
import 'package:receipt_scanner_flutter/screens/receipt_search_delegate.dart';
import 'package:receipt_scanner_flutter/screens/receipt_filter_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final receiptProvider = Provider.of<ReceiptProvider>(context);
    final currentMonthKey = budgetProvider.getCurrentMonthKey();
    final totalBudget = budgetProvider.getTotalBudgetForMonth(currentMonthKey);
    final monthlySpending = receiptProvider.getMonthlySpending();
    final languageProvider = Provider.of<LanguageProvider>(context);

    // Filtrer les reçus en fonction de la recherche
    final filteredReceipts = _searchQuery.isEmpty
        ? receiptProvider.filteredReceipts
        : receiptProvider.filteredReceipts.where((receipt) {
            final searchLower = _searchQuery.toLowerCase();
            final category = CategoryService.getCategoryById(receipt.category);
            return receipt.company.toLowerCase().contains(searchLower) ||
                receipt.notes?.toLowerCase().contains(searchLower) == true ||
                receipt.items.any((item) => item.name.toLowerCase().contains(searchLower)) ||
                category.name.toLowerCase().contains(searchLower);
          }).toList();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(languageProvider.translate('receipt_scanner'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: languageProvider.translate('budget'),
                      value: CurrencyFormatter.format(totalBudget),
                      icon: '💰',
                      color: const Color(0xFF10B981),
                      subtitle: languageProvider.translate('this_month'),
                      onTap: () => context.go('/budget'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: languageProvider.translate('spent'),
                      value: monthlySpending.toStringAsFixed(2),
                      icon: '📊',
                      color: const Color(0xFFF59E0B),
                      subtitle: totalBudget > 0 ? '${((monthlySpending / totalBudget) * 100).toStringAsFixed(0)}%' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Barre de recherche
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: languageProvider.translate('search_receipts'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1F2937)
                      : Colors.grey[100],
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    languageProvider.translate('recent_receipts'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: receiptProvider.hasActiveFilters ? AppTheme.primaryColor : null,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: ReceiptFilterSheet(
                            initialFilters: receiptProvider.currentFilters,
                            onFilterApplied: (filters) {
                              if (filters.isEmpty) {
                                receiptProvider.clearFilters();
                              } else {
                                receiptProvider.setFilters(filters);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filteredReceipts.isEmpty)
                Text(languageProvider.translate('no_receipts')),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredReceipts.length,
                  itemBuilder: (context, index) {
                    final receipt = filteredReceipts[index];
                    return _buildReceiptCard(context, receipt);
                  },
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildReceiptCard(BuildContext context, Receipt receipt) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.go('/receipt/${receipt.id}');
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          key: ValueKey('receipt_${receipt.id}'),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF1F2937) 
                : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CategoryService.getDefaultCategories().firstWhere(
                        (cat) => cat.id == receipt.category,
                        orElse: () => CategoryService.getDefaultCategories().first,
                      ).color,
                      CategoryService.getDefaultCategories().firstWhere(
                        (cat) => cat.id == receipt.category,
                        orElse: () => CategoryService.getDefaultCategories().first,
                      ).color.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Center(
                  child: Text(
                    CategoryService.getDefaultCategories().firstWhere(
                      (cat) => cat.id == receipt.category,
                      orElse: () => CategoryService.getDefaultCategories().first,
                    ).icon,
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
                        color: CategoryService.getDefaultCategories().firstWhere(
                          (cat) => cat.id == receipt.category,
                          orElse: () => CategoryService.getDefaultCategories().first,
                        ).color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: CategoryService.getDefaultCategories().firstWhere(
                            (cat) => cat.id == receipt.category,
                            orElse: () => CategoryService.getDefaultCategories().first,
                          ).color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        CategoryService.getDefaultCategories().firstWhere(
                          (cat) => cat.id == receipt.category,
                          orElse: () => CategoryService.getDefaultCategories().first,
                        ).name,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: CategoryService.getDefaultCategories().firstWhere(
                            (cat) => cat.id == receipt.category,
                            orElse: () => CategoryService.getDefaultCategories().first,
                          ).color,
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
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String icon,
    required Color color,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1F2937)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ],
        ),
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