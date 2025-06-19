import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_scanner_flutter/providers/plaid_provider.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/widgets/modern_app_bar.dart';
import 'package:receipt_scanner_flutter/widgets/modern_card.dart';
import 'package:receipt_scanner_flutter/screens/plaid_link_screen.dart';

class BankConnectionScreen extends StatefulWidget {
  const BankConnectionScreen({super.key});

  @override
  State<BankConnectionScreen> createState() => _BankConnectionScreenState();
}

class _BankConnectionScreenState extends State<BankConnectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final plaidProvider = Provider.of<PlaidProvider>(context, listen: false);
      if (plaidProvider.isConnected) {
        plaidProvider.loadConnectedAccounts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final plaidProvider = Provider.of<PlaidProvider>(context);
    final receiptProvider = Provider.of<ReceiptProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ModernAppBar(
          title: 'Connexion bancaire',
          showBackButton: true,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête explicatif avec Plaid
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🏦', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Synchronisation bancaire',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('Powered by ', style: TextStyle(fontSize: 12)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D4AA),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Plaid',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Connectez votre compte bancaire pour importer automatiquement vos transactions et créer des reçus. Plaid connecte plus de 12,000 institutions financières.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.infoColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: AppTheme.infoColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sécurité bancaire de niveau institutionnel. Vos identifiants ne sont jamais stockés.',
                            style: TextStyle(
                              color: AppTheme.infoColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingM),

            // État de la connexion
            if (!plaidProvider.isConnected) ...[
              ModernCard(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.textTertiary.withOpacity(0.1),
                            AppTheme.textTertiary.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance,
                        size: 48,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'Aucun compte connecté',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Connectez votre banque pour commencer la synchronisation automatique de vos transactions.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: plaidProvider.isConnecting ? null : _connectBank,
                          icon: plaidProvider.isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_link, color: Colors.white),
                          label: Text(
                            plaidProvider.isConnecting
                                ? 'Connexion en cours...'
                                : 'Connecter avec Plaid',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Comptes connectés
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: AppTheme.successColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Comptes connectés',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showDisconnectDialog(),
                          icon: Icon(
                            Icons.link_off,
                            size: 16,
                            color: AppTheme.errorColor,
                          ),
                          label: Text(
                            'Déconnecter',
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    ...plaidProvider.connectedAccounts.map((account) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.successColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance,
                              color: AppTheme.successColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account['institution_name'] ?? 'Banque',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${account['name']} (${account['subtype']})',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                'Actif',
                                style: TextStyle(
                                  color: AppTheme.successColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingM),

              // Synchronisation
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Synchronisation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    if (plaidProvider.lastSyncDate != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.sync,
                            color: AppTheme.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dernière sync: ${_formatDate(plaidProvider.lastSyncDate!)}',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: plaidProvider.isSyncing
                                ? null
                                : () => plaidProvider.syncTransactions(receiptProvider),
                            icon: plaidProvider.isSyncing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(
                              plaidProvider.isSyncing
                                  ? 'Synchronisation...'
                                  : 'Sync maintenant',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: plaidProvider.isSyncing
                              ? null
                              : () => _showSyncOptionsDialog(receiptProvider),
                          icon: const Icon(Icons.date_range, size: 16),
                          label: const Text('Options'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Erreurs
            if (plaidProvider.error != null) ...[
              const SizedBox(height: AppTheme.spacingM),
              ModernCard(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          plaidProvider.error!,
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: plaidProvider.clearError,
                        icon: Icon(
                          Icons.close,
                          color: AppTheme.errorColor,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Informations sur Plaid
            const SizedBox(height: AppTheme.spacingM),
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À propos de Plaid',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Plaid est utilisé par des milliers d\'applications financières pour connecter en toute sécurité les comptes bancaires. Vos identifiants bancaires ne sont jamais stockés et toutes les connexions sont chiffrées.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: AppTheme.successColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Certifié SOC 2 Type II',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.lock,
                        color: AppTheme.successColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Chiffrement 256-bit',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectBank() async {
    final plaidProvider = Provider.of<PlaidProvider>(context, listen: false);
    
    final linkToken = await plaidProvider.createLinkToken();
    
    if (linkToken != null && mounted) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PlaidLinkScreen(linkToken: linkToken),
        ),
      );
      
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Compte bancaire connecté avec succès!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnecter Plaid'),
        content: const Text(
          'Êtes-vous sûr de vouloir déconnecter votre compte bancaire ? '
          'La synchronisation automatique sera désactivée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final plaidProvider = Provider.of<PlaidProvider>(context, listen: false);
              await plaidProvider.disconnectAll();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compte bancaire déconnecté'),
                  ),
                );
              }
            },
            child: Text(
              'Déconnecter',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncOptionsDialog(ReceiptProvider receiptProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Options de synchronisation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Dernières 24h'),
              onTap: () {
                Navigator.of(context).pop();
                _syncWithDateRange(receiptProvider, 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Derniers 7 jours'),
              onTap: () {
                Navigator.of(context).pop();
                _syncWithDateRange(receiptProvider, 7);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Dernier mois'),
              onTap: () {
                Navigator.of(context).pop();
                _syncWithDateRange(receiptProvider, 30);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _syncWithDateRange(ReceiptProvider receiptProvider, int days) {
    final plaidProvider = Provider.of<PlaidProvider>(context, listen: false);
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    plaidProvider.syncTransactions(
      receiptProvider,
      startDate: startDate,
      endDate: endDate,
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date inconnue';
    }
  }
}