import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/providers/budget_provider.dart';
import 'package:receipt_scanner_flutter/widgets/receipt_card.dart';
import 'package:receipt_scanner_flutter/widgets/modern_card.dart';
import 'package:receipt_scanner_flutter/widgets/stat_card.dart';
import 'package:receipt_scanner_flutter/widgets/animated_fab.dart';
import 'package:receipt_scanner_flutter/utils/currency_formatter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const HomeTab(),
    const ScanTab(),
    const ManualEntryTab(),
    const BudgetTab(),
    const ReportsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.home, languageProvider.translate('home')),
                _buildNavItem(1, LucideIcons.camera, languageProvider.translate('scan'), isSpecial: true),
                _buildNavItem(2, LucideIcons.plus, languageProvider.translate('manual_entry')),
                _buildNavItem(3, LucideIcons.wallet, languageProvider.translate('budget')),
                _buildNavItem(4, LucideIcons.barChart3, languageProvider.translate('reports')),
                _buildNavItem(5, LucideIcons.settings, languageProvider.translate('settings')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isSpecial = false}) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (isSpecial) {
          _fabAnimationController.reset();
          _fabAnimationController.forward();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSpecial ? AppTheme.spacingM : AppTheme.spacingS,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSpecial 
              ? AppTheme.primaryColor
              : isSelected 
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(
            isSpecial ? AppTheme.radiusLarge : AppTheme.radiusSmall,
          ),
          boxShadow: isSpecial ? [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Icon(
          icon,
          color: isSpecial 
              ? Colors.white
              : isSelected 
                  ? AppTheme.primaryColor
                  : AppTheme.textTertiary,
          size: isSpecial ? 28 : 24,
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

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
                        child: StatCard(
                          title: languageProvider.translate('total_budget'),
                          value: CurrencyFormatter.format(totalBudget),
                          icon: LucideIcons.target,
                          iconColor: AppTheme.successColor,
                          subtitle: 'Ce mois',
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: StatCard(
                          title: languageProvider.translate('monthly_spending'),
                          value: CurrencyFormatter.format(monthlySpending),
                          icon: LucideIcons.trendingUp,
                          iconColor: AppTheme.warningColor,
                          subtitle: totalBudget > 0 
                              ? '${((monthlySpending / totalBudget) * 100).toStringAsFixed(0)}% utilisé'
                              : null,
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
                        onPressed: () {
                          // Navigate to all receipts
                        },
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
                    ModernCard(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.receipt,
                              size: 48,
                              color: AppTheme.primaryColor,
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
                                  icon: const Icon(LucideIcons.camera),
                                  label: const Text('Scanner'),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.go('/manual-entry'),
                                  icon: const Icon(LucideIcons.plus),
                                  label: const Text('Ajouter'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    ...receiptProvider.recentReceipts.map(
                      (receipt) => ReceiptCard(
                        receipt: receipt,
                        onTap: () => context.go('/receipt/${receipt.id}'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder tabs avec le nouveau design
class ScanTab extends StatelessWidget {
  const ScanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ModernCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.camera,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Scanner un reçu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ManualEntryTab extends StatelessWidget {
  const ManualEntryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ModernCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.plus,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Ajouter manuellement',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ModernCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.wallet,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Gérer le budget',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ModernCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.barChart3,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Voir les rapports',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ModernCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.settings,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Paramètres',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}