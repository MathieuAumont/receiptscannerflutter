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
import 'package:receipt_scanner_flutter/providers/category_provider.dart';
import 'package:receipt_scanner_flutter/widgets/receipt_card.dart';
import 'package:receipt_scanner_flutter/widgets/modern_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
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
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // App Bar moderne
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '💰',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            languageProvider.translate('receipt_scanner'),
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(
                    left: 0,
                    bottom: 16,
                  ),
                ),
              ),
              
              // Contenu principal
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cartes de statistiques avec gradients
                      Row(
                        children: [
                          Expanded(
                            child: _buildGradientStatCard(
                              context,
                              title: languageProvider.translate('budget'),
                              value: CurrencyFormatter.format(totalBudget),
                              icon: '💰',
                              gradient: AppTheme.primaryGradient,
                              subtitle: languageProvider.translate('this_month'),
                              onTap: () => context.go('/budget'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: _buildGradientStatCard(
                              context,
                              title: languageProvider.translate('spent'),
                              value: CurrencyFormatter.format(monthlySpending),
                              icon: '📊',
                              gradient: AppTheme.secondaryGradient,
                              subtitle: totalBudget > 0 ? '${((monthlySpending / totalBudget) * 100).toStringAsFixed(0)}%' : null,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.spacingXL),
                      
                      // Actions rapides
                      ModernCard(
                        gradient: AppTheme.accentGradient,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Actions rapides',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Scanner ou ajouter un reçu',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildQuickActionButton(
                                  icon: Icons.camera_alt,
                                  onTap: () => context.go('/scan'),
                                ),
                                const SizedBox(width: 12),
                                _buildQuickActionButton(
                                  icon: Icons.add,
                                  onTap: () => context.go('/manual-entry'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingXL),
                      
                      // Barre de recherche moderne
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher des reçus...',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
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
                                : IconButton(
                                    icon: Icon(
                                      Icons.tune,
                                      color: receiptProvider.hasActiveFilters ? AppTheme.primaryColor : AppTheme.textTertiary,
                                    ),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
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
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingM,
                              vertical: AppTheme.spacingM,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingXL),
                      
                      // En-tête des reçus récents
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languageProvider.translate('recent_receipts'),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (filteredReceipts.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${filteredReceipts.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Liste des reçus ou état vide
                      if (filteredReceipts.isEmpty)
                        _buildEmptyState(context, languageProvider)
                      else
                        ...filteredReceipts.map((receipt) {
                          final category = categories.firstWhere(
                            (cat) => cat.id == receipt.category,
                            orElse: () => categories.isNotEmpty
                                ? categories.first
                                : Category(
                                    id: 'other',
                                    name: 'Other',
                                    icon: '📄',
                                    color: AppTheme.categoryColors[6],
                                  ),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                            child: ReceiptCard(receipt: receipt, category: category),
                          );
                        }),
                      
                      const SizedBox(height: AppTheme.spacingXXL),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String icon,
    required Gradient gradient,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 8,
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
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, LanguageProvider languageProvider) {
    return ModernCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
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
              fontWeight: FontWeight.w700,
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
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/scan'),
                    icon: const Text('📷'),
                    label: const Text('Scanner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/manual-entry'),
                  icon: const Text('➕'),
                  label: const Text('Ajouter'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}