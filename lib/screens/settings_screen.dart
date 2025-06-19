import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/theme_provider.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/providers/flinks_provider.dart';
import 'package:receipt_scanner_flutter/widgets/modern_app_bar.dart';
import 'package:receipt_scanner_flutter/widgets/modern_card.dart';
import 'package:receipt_scanner_flutter/services/storage_service.dart';
import 'package:receipt_scanner_flutter/screens/help_support_screen.dart';
import 'package:receipt_scanner_flutter/screens/manage_categories_screen.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:receipt_scanner_flutter/models/category.dart';
import 'package:receipt_scanner_flutter/providers/category_provider.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final receiptProvider = Provider.of<ReceiptProvider>(context);
    final flinksProvider = Provider.of<FlinksProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ModernAppBar(
          title: languageProvider.translate('settings'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preferences Section
            _buildSectionHeader(context, languageProvider.translate('preferences')),
            
            ModernCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Icon(
                          LucideIcons.moon,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Text(languageProvider.translate('dark_mode')),
                      ),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(),
                      ),
                    ],
                  ),
                  
                  const Divider(),
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Icon(
                          LucideIcons.globe,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(languageProvider.translate('language')),
                            Text(
                              languageProvider.isFrench ? 'Français' : 'English',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: !languageProvider.isFrench,
                        onChanged: (value) => languageProvider.toggleLanguage(),
                      ),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(Icons.category, color: AppTheme.primaryColor),
                    ),
                    title: Text(languageProvider.translate('manage_categories')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ManageCategoriesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Banking Section
            _buildSectionHeader(context, 'Banque'),
            
            ModernCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: flinksProvider.isConnected 
                            ? AppTheme.successColor.withOpacity(0.1)
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        color: flinksProvider.isConnected 
                            ? AppTheme.successColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                    title: Text('Connexion bancaire'),
                    subtitle: Text(
                      flinksProvider.isConnected 
                          ? 'Connecté - Synchronisation automatique active'
                          : 'Non connecté - Connectez votre banque pour importer automatiquement vos transactions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: flinksProvider.isConnected 
                            ? AppTheme.successColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (flinksProvider.isConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Connecté',
                              style: TextStyle(
                                color: AppTheme.successColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () => context.go('/bank-connection'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Data Management Section
            _buildSectionHeader(context, languageProvider.translate('data_management')),
            
            ModernCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        LucideIcons.database,
                        color: AppTheme.infoColor,
                      ),
                    ),
                    title: Text(languageProvider.translate('storage_used')),
                    subtitle: Text(languageProvider.translate('storage_used_subtitle').replaceAll('{count}', receiptProvider.receipts.length.toString())),
                    trailing: const Icon(LucideIcons.chevronRight),
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        LucideIcons.download,
                        color: AppTheme.successColor,
                      ),
                    ),
                    title: Text(languageProvider.translate('export_data')),
                    subtitle: Text(languageProvider.translate('export_csv')),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      // TODO: Implement export functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(languageProvider.translate('export_coming_soon'))),
                      );
                    },
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        LucideIcons.trash2,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    title: Text(
                      languageProvider.translate('clear_all_data'),
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                    subtitle: Text(languageProvider.translate('delete_all_data_subtitle')),
                    onTap: () => _showClearDataDialog(context, receiptProvider),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // About Section
            _buildSectionHeader(context, languageProvider.translate('about')),
            
            ModernCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        LucideIcons.helpCircle,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(languageProvider.translate('help_support')),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        LucideIcons.info,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(languageProvider.translate('version')),
                    subtitle: Text(languageProvider.translate('app_version').replaceAll('{version}', '1.0.0')),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            const SizedBox(height: AppTheme.spacingXXL),
            
            // Footer
            Center(
              child: Text(
                languageProvider.translate('footer_copyright').replaceAll('{year}', DateTime.now().year.toString()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingS,
        bottom: AppTheme.spacingS,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, ReceiptProvider receiptProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Provider.of<LanguageProvider>(context, listen: false).translate('clear_all_data')),
        content: Text(Provider.of<LanguageProvider>(context, listen: false).translate('clear_all_data_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              try {
                await StorageService().clearAllData();
                await receiptProvider.loadReceipts();
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(Provider.of<LanguageProvider>(context, listen: false).translate('clear_all_data_success')),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(Provider.of<LanguageProvider>(context, listen: false).translate('clear_all_data_error')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              Provider.of<LanguageProvider>(context, listen: false).translate('delete'),
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryManagerInline extends StatefulWidget {
  @override
  State<_CategoryManagerInline> createState() => _CategoryManagerInlineState();
}

class _CategoryManagerInlineState extends State<_CategoryManagerInline> {
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextField(
                controller: _iconController,
                decoration: const InputDecoration(labelText: 'Emoji'),
                maxLength: 2,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final color = await showDialog<Color>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Choisir une couleur'),
                    content: SingleChildScrollView(
                      child: BlockPicker(
                        pickerColor: _selectedColor,
                        onColorChanged: (color) {
                          Navigator.of(context).pop(color);
                        },
                      ),
                    ),
                  ),
                );
                if (color != null) {
                  setState(() {
                    _selectedColor = color;
                  });
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.trim().isEmpty || _iconController.text.trim().isEmpty) return;
                final newCategory = Category(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _nameController.text.trim(),
                  icon: _iconController.text.trim(),
                  color: _selectedColor,
                  isCustom: true,
                );
                await categoryProvider.addCategory(newCategory);
                _nameController.clear();
                _iconController.clear();
                setState(() {
                  _selectedColor = Colors.blue;
                });
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) => Chip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cat.icon),
                const SizedBox(width: 4),
                Text(cat.name),
              ],
            ),
            backgroundColor: cat.color.withOpacity(0.15),
            deleteIcon: cat.isCustom ? const Icon(Icons.close) : null,
            onDeleted: cat.isCustom ? () async {
              await categoryProvider.deleteCategory(cat.id);
            } : null,
          )).toList(),
        ),
      ],
    );
  }
}