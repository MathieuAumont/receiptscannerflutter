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

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime _selectedMonth = DateTime.now();
  bool _isEditing = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
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
    final categories = CategoryService.getDefaultCategories();

    final currentBudget = budgetProvider.getBudgetForMonth(_monthKey);
    final totalBudget = budgetProvider.getTotalBudgetForMonth(_monthKey);
    final monthlySpending = receiptProvider.getMonthlySpending(_selectedMonth);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ModernAppBar(
          title: languageProvider.translate('budget'),
          showBackButton: false,
          actions: [
            if (_isEditing)
              TextButton(
                onPressed: _saveBudget,
                child: Text(languageProvider.translate('save_budget')),
              )
            else
              IconButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                  _initializeControllers(currentBudget, categories);
                },
                icon: const Icon(LucideIcons.edit),
                tooltip: languageProvider.translate('edit_budget'),
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            // Month Selector
            ModernCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                    },
                    icon: const Icon(LucideIcons.chevronLeft),
                  ),
                  Column(
                    children: [
                      Text(
                        languageProvider.translate('month_format').replaceAll('{month}', _getMonthName(_selectedMonth)),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_isCurrentMonth())
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingS,
                            vertical: AppTheme.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      });
                    },
                    icon: const Icon(LucideIcons.chevronRight),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Budget Summary
            ModernCard(
              child: Column(
                children: [
                  Text(
                    languageProvider.translate('total_monthly_budget'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        CurrencyFormatter.format(monthlySpending),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' / ${CurrencyFormatter.format(totalBudget)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  LinearProgressIndicator(
                    value: totalBudget > 0 ? (monthlySpending / totalBudget).clamp(0.0, 1.0) : 0.0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(monthlySpending, totalBudget),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    totalBudget > 0 
                        ? languageProvider.translate('percent_used').replaceAll('{percent}', ((monthlySpending / totalBudget) * 100).toStringAsFixed(1))
                        : languageProvider.translate('no_budget_set'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Categories List
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
                padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                child: ModernCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
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
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languageProvider.translate('category_${category.id}'),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                controller: _controllers[category.id],
                                decoration: const InputDecoration(
                                  prefixText: '\$',
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
                            Text(
                              budgetItem.amount > 0 
                                  ? '${((categorySpending / budgetItem.amount) * 100).toStringAsFixed(0)}%'
                                  : '0%',
                              style: TextStyle(
                                color: _getProgressColor(categorySpending, budgetItem.amount),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                      if (budgetItem.amount > 0) ...[
                        const SizedBox(height: AppTheme.spacingM),
                        LinearProgressIndicator(
                          value: (categorySpending / budgetItem.amount).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(categorySpending, budgetItem.amount),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
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
    final categories = CategoryService.getDefaultCategories();
    
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  Color _getProgressColor(double spent, double budget) {
    if (budget == 0) return Colors.grey;
    final percentage = spent / budget;
    if (percentage >= 1.0) return AppTheme.errorColor;
    if (percentage >= 0.8) return AppTheme.warningColor;
    return AppTheme.successColor;
  }
}