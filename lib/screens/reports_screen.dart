import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/models/category.dart';
import 'package:receipt_scanner_flutter/widgets/modern_card.dart';
import 'package:receipt_scanner_flutter/widgets/stat_card.dart';
import 'package:receipt_scanner_flutter/utils/currency_formatter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final receiptProvider = Provider.of<ReceiptProvider>(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  languageProvider.translate('reports'),
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
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: languageProvider.translate('tab_analysis')),
                    Tab(text: languageProvider.translate('tab_ai')),
                    Tab(text: languageProvider.translate('tab_report')),
                  ],
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAnalysisTab(receiptProvider),
            _buildAITab(),
            _buildCustomReportTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTab(ReceiptProvider receiptProvider) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Stats
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  title: languageProvider.translate('total'),
                  value: CurrencyFormatter.format(receiptProvider.totalSpending),
                  icon: '💰',
                  color: const Color(0xFF10B981),
                  onTap: () => context.go('/budget'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildModernStatCard(
                  title: languageProvider.translate('receipts'),
                  value: receiptProvider.receipts.length.toString(),
                  icon: '📄',
                  color: const Color(0xFF6366F1),
                  onTap: () => context.go('/analysis'),
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
                    const Text('📊', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      languageProvider.translate('category_breakdown'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                if (receiptProvider.receipts.isNotEmpty)
                  _buildCategoryChart(receiptProvider)
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingXXL),
                      child: Text(languageProvider.translate('no_data_available')),
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
                    const Text('📈', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      languageProvider.translate('monthly_trend'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                if (receiptProvider.receipts.isNotEmpty)
                  _buildMonthlyChart(receiptProvider)
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingXXL),
                      child: Text(languageProvider.translate('no_data_available')),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAITab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          ModernCard(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8B5CF6),
                        const Color(0xFF8B5CF6).withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🤖', style: TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: AppTheme.spacingL),
                Text(
                  'Assistant IA',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Posez des questions sur vos dépenses et obtenez des insights personnalisés',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/analysis'),
                    icon: const Text('🚀'),
                    label: const Text('Commencer l\'analyse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Questions suggérées
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questions suggérées',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                ...[
                  '💰 Quel est mon total de dépenses ce mois ?',
                  '📊 Dans quelle catégorie je dépense le plus ?',
                  '📈 Comment évoluent mes dépenses ?',
                  '💡 Comment puis-je économiser ?',
                ].map((question) => Padding(
                  key: ValueKey(question),
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Text(question),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          ModernCard(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B),
                        const Color(0xFFF59E0B).withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('📋', style: TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: AppTheme.spacingL),
                Text(
                  'Rapport personnalisé',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Créez un rapport détaillé pour une période spécifique',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/custom-report'),
                    icon: const Text('📊'),
                    label: const Text('Créer un rapport'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Types de rapports
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Types de rapports disponibles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                ...[
                  {'icon': '📅', 'title': 'Rapport mensuel', 'desc': 'Analyse complète du mois'},
                  {'icon': '📊', 'title': 'Rapport par catégorie', 'desc': 'Détail par type de dépense'},
                  {'icon': '📈', 'title': 'Rapport de tendance', 'desc': 'Évolution sur plusieurs mois'},
                  {'icon': '💰', 'title': 'Rapport budgétaire', 'desc': 'Comparaison budget vs réel'},
                ].map((item) => Padding(
                  key: ValueKey(item.hashCode),
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          item['icon']!,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              item['desc']!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required String icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return ModernCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(height: AppTheme.spacingS),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppTheme.textTertiary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(ReceiptProvider receiptProvider) {
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
            key: ValueKey(category.id),
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
                Text(category.icon),
                const SizedBox(width: AppTheme.spacingXS),
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

  Widget _buildMonthlyChart(ReceiptProvider receiptProvider) {
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
            gradient: AppTheme.primaryGradient,
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
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                   'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[date.month - 1];
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}