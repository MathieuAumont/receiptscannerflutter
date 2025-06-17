import 'package:flutter/material.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/widgets/modern_app_bar.dart';
import 'package:receipt_scanner_flutter/widgets/modern_card.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:provider/provider.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ModernAppBar(
          title: languageProvider.translate('help_support'),
          showBackButton: true,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(languageProvider.translate('help_welcome'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(languageProvider.translate('help_features_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(languageProvider.translate('help_features_scan')),
                  const SizedBox(height: 8),
                  Text(languageProvider.translate('help_features_manual')),
                  const SizedBox(height: 8),
                  Text(languageProvider.translate('help_features_analysis')),
                  const SizedBox(height: 8),
                  Text(languageProvider.translate('help_features_budget')),
                  const SizedBox(height: 8),
                  Text(languageProvider.translate('help_features_export')),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(languageProvider.translate('help_examples_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(languageProvider.translate('help_example_scan_groceries')),
                  const SizedBox(height: 8),
                  Text(languageProvider.translate('help_example_manual_online')),
                  const SizedBox(height: 8),
                  Text(languageProvider.translate('help_example_monthly_report')),
                  const SizedBox(height: 8),
                  Text(languageProvider.translate('help_example_budget_restaurant')),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(languageProvider.translate('help_need_help'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(languageProvider.translate('help_contact')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 