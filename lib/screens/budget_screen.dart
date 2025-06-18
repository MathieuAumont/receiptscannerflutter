import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/budget_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/models/category.dart';
import 'package:receipt_scanner_flutter/widgets/modern_app_bar.dart';
import 'package:receipt_scanner_flutter/widgets/modern_card.dart';
import 'package:receipt_scanner_flutter/utils/currency_formatter.dart';
import 'package:receipt_scanner_flutter/screens/monthly_receipts_screen.dart';
import 'package:receipt_scanner_flutter/providers/category_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with TickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  bool _isEditing = false;
  final Map<String, TextEditingController> _controllers = {};
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
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
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  String get _monthKey {
    return '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final receiptProvider = Provider.of<ReceiptProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;
    
    final currentBudget = budgetProvider.getBudgetForMonth(_monthKey);
    final monthlySpending = receiptProvider.receipts
        .where((receipt) => 
            receipt.date.year == _selectedMonth.year &&
            receipt.date.month == _selectedMonth.month)
        .fold(0.0, (sum, receipt) => sum + receipt.totalAmount);
    
    final totalBudget = currentBudget.fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ModernAppBar(
          title: languageProvider.translate('budget'),
          showBackButton: false,
          actions: [
            if (_isEditing)
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: _saveBudget,
                  child: const Text(
                    'Sauvegarder',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                    _initializeControllers(currentBudget, categories);
                  },
                  icon: Icon(
                    LucideIcons.edit,
                    color: AppTheme.primaryColor,
                  ),
                  tooltip: languageProvider.translate('edit_budget'),
                ),
              ),
          ],
        ),
      ),
      body: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: FadeTransition(
          opacity: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              children: [
                // Sélecteur de mois moderne
                ModernCard(
                  gradient: AppTheme.secondaryGradient,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month - 1,
                              );
                            });
                          },
                          icon: const Icon(
                            LucideIcons.chevronLeft,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            _getMonthName(_selectedMonth),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          if (_isCurrentMonth())
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                languageProvider.translate('current_month'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month + 1,
                              );
                            });
                          },
                          icon: const Icon(
                            LucideIcons.chevronRight,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // Résumé du budget avec gradient
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MonthlyReceiptsScreen(month: _selectedMonth),
                      ),
                    );
                  },
                  child: ModernCard(
                    gradient: AppTheme.primaryGradient,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('💰', style: TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                languageProvider.translate('total_monthly_budget'),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              CurrencyFormatter.format(monthlySpending),
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              ' / ${CurrencyFormatter.format(totalBudget)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: totalBudget > 0 ? (monthlySpending / totalBudget).clamp(0.0, 1.0) : 0.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          totalBudget > 0 
                              ? languageProvider.translate('percent_used').replaceAll('{percent}', ((monthlySpending / totalBudget) * 100).toStringAsFixed(1))
                              : languageProvider.translate('no_budget_set'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // Liste des catégories
                ...categories.map((category) {
                  final budgetItem = currentBudget.firstWhere(
                    (item) => item.categoryId == category.id,
                    orElse: () => BudgetItem(categoryId: category.id, amount: 0),
                  );
                  
                  final categorySpending = receiptProvider.receipts
                      .where((receipt) => 
                          receipt.category == category.id &&
                          receipt.date.year == _selectedMonth.year &&
                          receipt.date.month == _selectedMonth.month)
                      .fold(0.0, (sum, receipt) => sum + receipt.totalAmount);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                    child: ModernCard(
                      child: Column(
                        children: [
                          Row(
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: category.color.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.isCustom ? category.name : languageProvider.translate('category_${category.id}'),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: CurrencyFormatter.format(categorySpending),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const TextSpan(text: ' / '),
                                          TextSpan(text: CurrencyFormatter.format(budgetItem.amount)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isEditing)
                                Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextFormField(
                                    controller: _controllers[category.id],
                                    decoration: const InputDecoration(
                                      prefixText: '\$',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingS,
                                        vertical: AppTheme.spacingS,
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getProgressColor(categorySpending, budgetItem.amount),
                                        _getProgressColor(categorySpending, budgetItem.amount).withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    budgetItem.amount > 0 
                                        ? '${((categorySpending / budgetItem.amount) * 100).toStringAsFixed(0)}%'
                                        : '0%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (budgetItem.amount > 0) ...[
                            const SizedBox(height: AppTheme.spacingM),
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: (categorySpending / budgetItem.amount).clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getProgressColor(categorySpending, budgetItem.amount),
                                        _getProgressColor(categorySpending, budgetItem.amount).withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _initializeControllers(List<BudgetItem> currentBudget, List<Category> categories) {
    _controllers.clear();
    for (final category in categories) {
      final budgetItem = currentBudget.firstWhere(
        (item) => item.categoryId == category.id,
        orElse: () => BudgetItem(categoryId: category.id, amount: 0),
      );
      _controllers[category.id] = TextEditingController(
        text: budgetItem.amount > 0 ? budgetItem.amount.toString() : '',
      );
    }
  }

  Future<void> _saveBudget() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    
    try {
      final budgetItems = _controllers.entries.map((entry) {
        final amount = double.tryParse(entry.value.text) ?? 0.0;
        return BudgetItem(
          categoryId: entry.key,
          amount: amount,
        );
      }).toList();

      await budgetProvider.setBudgetForMonth(_monthKey, budgetItems);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.translate('budget_updated')),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.translate('budget_update_error')),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  Color _getProgressColor(double spent, double budget) {
    if (budget == 0) return AppTheme.textTertiary;
    final percentage = spent / budget;
    if (percentage >= 1.0) return AppTheme.errorColor;
    if (percentage >= 0.8) return AppTheme.warningColor;
    return AppTheme.successColor;
  }
}