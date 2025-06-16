import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/models/category.dart';
import 'package:receipt_scanner_flutter/widgets/modern_app_bar.dart';
import 'package:receipt_scanner_flutter/widgets/modern_card.dart';
import 'package:receipt_scanner_flutter/widgets/stat_card.dart';
import 'package:receipt_scanner_flutter/utils/currency_formatter.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final receiptProvider = Provider.of<ReceiptProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ModernAppBar(
          title: languageProvider.translate('reports'),
          showBackButton: true,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Stats
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Expenses',
                    value: CurrencyFormatter.format(receiptProvider.totalSpending),
                    icon: LucideIcons.dollarSign,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: StatCard(
                    title: 'Number of Receipts',
                    value: receiptProvider.receipts.length.toString(),
                    icon: LucideIcons.receipt,
                    iconColor: AppTheme.successColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Category Breakdown
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.pieChart,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Category Breakdown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  if (receiptProvider.receipts.isNotEmpty)
                    _buildCategoryChart(context, receiptProvider)
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacingXXL),
                        child: Text('No data available'),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Monthly Trend
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.trendingUp,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Monthly Trend',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  if (receiptProvider.receipts.isNotEmpty)
                    _buildMonthlyChart(context, receiptProvider)
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacingXXL),
                        child: Text('No data available'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(BuildContext context, ReceiptProvider receiptProvider) {
    final categories = CategoryService.getDefaultCategories();
    final categoryTotals = receiptProvider.getCategoryTotals();
    
    final pieChartData = categories
        .where((category) => categoryTotals[category.id] != null && categoryTotals[category.id]! > 0)
        .map((category) {
          final amount = categoryTotals[category.id]!;
          final percentage = (amount / receiptProvider.totalSpending) * 100;
          
          return PieChartSectionData(
            color: category.color,
            value: amount,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          );
        })
        .toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: pieChartData,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        ...categories
            .where((category) => categoryTotals[category.id] != null && categoryTotals[category.id]! > 0)
            .map((category) {
          final amount = categoryTotals[category.id]!;
          final percentage = (amount / receiptProvider.totalSpending) * 100;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(category.name),
                ),
                Text(
                  CurrencyFormatter.format(amount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthlyChart(BuildContext context, ReceiptProvider receiptProvider) {
    final now = DateTime.now();
    final monthlyData = <String, double>{};
    
    // Get last 6 months of data
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthName = _getShortMonthName(month);
      
      final monthlySpending = receiptProvider.receipts
          .where((receipt) => 
              receipt.date.year == month.year && 
              receipt.date.month == month.month)
          .fold(0.0, (sum, receipt) => sum + receipt.totalAmount);
      
      monthlyData[monthName] = monthlySpending;
    }

    final maxY = monthlyData.values.isNotEmpty 
        ? monthlyData.values.reduce((a, b) => a > b ? a : b) * 1.2
        : 100.0;

    final barGroups = monthlyData.entries.map((entry) {
      final index = monthlyData.keys.toList().indexOf(entry.key);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: AppTheme.primaryColor,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < monthlyData.keys.length) {
                    return Text(
                      monthlyData.keys.elementAt(index),
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  String _getShortMonthName(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }
}