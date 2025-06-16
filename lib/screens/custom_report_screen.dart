import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/widgets/modern_app_bar.dart';
import 'package:receipt_scanner_flutter/widgets/modern_card.dart';
import 'package:receipt_scanner_flutter/utils/currency_formatter.dart';
import 'package:receipt_scanner_flutter/utils/date_formatter.dart';

class CustomReportScreen extends StatefulWidget {
  const CustomReportScreen({super.key});

  @override
  State<CustomReportScreen> createState() => _CustomReportScreenState();
}

class _CustomReportScreenState extends State<CustomReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _reportType = 'monthly';
  bool _isGenerating = false;
  Map<String, dynamic>? _reportData;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ModernAppBar(
          title: 'Rapport personnalisé',
          showBackButton: true,
          onBackPressed: () => context.go('/reports'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration du rapport
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('⚙️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Configuration',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Type de rapport
                  Text(
                    'Type de rapport',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  ...['monthly', 'category', 'trend', 'budget'].map((type) {
                    final titles = {
                      'monthly': '📅 Rapport mensuel',
                      'category': '📊 Par catégorie',
                      'trend': '📈 Tendance',
                      'budget': '💰 Budgétaire',
                    };
                    
                    return RadioListTile<String>(
                      key: ValueKey(type),
                      contentPadding: EdgeInsets.zero,
                      title: Text(titles[type]!),
                      value: type,
                      groupValue: _reportType,
                      onChanged: (value) {
                        setState(() {
                          _reportType = value!;
                        });
                      },
                    );
                  }),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Période
                  Text(
                    'Période',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(LucideIcons.calendar),
                          title: const Text('Du'),
                          subtitle: Text(DateFormatter.format(_startDate)),
                          onTap: () => _selectDate(true),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(LucideIcons.calendar),
                          title: const Text('Au'),
                          subtitle: Text(DateFormatter.format(_endDate)),
                          onTap: () => _selectDate(false),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Bouton générer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateReport,
                      icon: _isGenerating 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('📊'),
                      label: Text(_isGenerating ? 'Génération...' : 'Générer le rapport'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Résultats du rapport
            if (_reportData != null) ...[
              const SizedBox(height: AppTheme.spacingM),
              _buildReportResults(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = date;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 30));
          }
        }
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    // Simuler la génération du rapport
    await Future.delayed(const Duration(seconds: 2));

    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
    final receipts = receiptProvider.receipts.where((receipt) =>
        receipt.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        receipt.date.isBefore(_endDate.add(const Duration(days: 1)))).toList();

    final totalAmount = receipts.fold(0.0, (sum, receipt) => sum + receipt.totalAmount);
    final averagePerDay = receipts.isNotEmpty 
        ? totalAmount / _endDate.difference(_startDate).inDays
        : 0.0;

    setState(() {
      _isGenerating = false;
      _reportData = {
        'receipts': receipts,
        'totalAmount': totalAmount,
        'averagePerDay': averagePerDay,
        'receiptCount': receipts.length,
        'period': '${DateFormatter.format(_startDate)} - ${DateFormatter.format(_endDate)}',
      };
    });
  }

  Widget _buildReportResults() {
    final data = _reportData!;
    
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Résultats du rapport',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          Text(
            'Période: ${data['period']}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Statistiques principales
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '💰',
                  'Total',
                  CurrencyFormatter.format(data['totalAmount']),
                  const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '📄',
                  'Reçus',
                  data['receiptCount'].toString(),
                  const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '📊',
                  'Moyenne/jour',
                  CurrencyFormatter.format(data['averagePerDay']),
                  const Color(0xFFF59E0B),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '📈',
                  'Période',
                  '${_endDate.difference(_startDate).inDays} jours',
                  const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter l'export PDF
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export PDF bientôt disponible!')),
                    );
                  },
                  icon: const Icon(LucideIcons.download),
                  label: const Text('Exporter PDF'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter le partage
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Partage bientôt disponible!')),
                    );
                  },
                  icon: const Icon(LucideIcons.share),
                  label: const Text('Partager'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      margin: const EdgeInsets.only(right: AppTheme.spacingS),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}