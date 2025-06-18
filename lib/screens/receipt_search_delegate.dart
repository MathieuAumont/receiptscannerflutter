import 'package:flutter/material.dart';
import 'package:receipt_scanner_flutter/models/receipt.dart';
import 'package:receipt_scanner_flutter/utils/currency_formatter.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/models/category.dart';
import 'package:intl/intl.dart';

class ReceiptSearchDelegate extends SearchDelegate<Receipt?> {
  final List<Receipt> receipts;
  final Function(Receipt) onReceiptSelected;

  ReceiptSearchDelegate({
    required this.receipts,
    required this.onReceiptSelected,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  bool _matchesDate(DateTime date, String searchTerm) {
    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    final monthStr = DateFormat('MMMM', 'fr_FR').format(date).toLowerCase();
    final monthStrEn = DateFormat('MMMM', 'en_US').format(date).toLowerCase();
    
    return dateStr.contains(searchTerm) || 
           monthStr.contains(searchTerm) ||
           monthStrEn.contains(searchTerm);
  }

  bool _matchesAmount(double amount, String searchTerm) {
    final amountStr = amount.toString();
    final formattedAmount = CurrencyFormatter.format(amount);
    
    return amountStr.contains(searchTerm) ||
           formattedAmount.toLowerCase().contains(searchTerm);
  }

  bool _matchesItems(List<ReceiptItem> items, String searchTerm) {
    return items.any((item) => 
      item.name.toLowerCase().contains(searchTerm) ||
      _matchesAmount(item.price, searchTerm) ||
      (item.quantity?.toString().contains(searchTerm) ?? false)
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Commencez à taper pour rechercher des reçus'),
      );
    }

    final searchLower = query.toLowerCase();
    final results = receipts.where((receipt) {
      final category = CategoryService.getCategoryById(receipt.category);
      
      // Recherche sur tous les critères
      return receipt.company.toLowerCase().contains(searchLower) ||
          receipt.notes?.toLowerCase().contains(searchLower) == true ||
          _matchesItems(receipt.items, searchLower) ||
          category.name.toLowerCase().contains(searchLower) ||
          _matchesDate(receipt.date, searchLower) ||
          _matchesAmount(receipt.totalAmount, searchLower);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun reçu trouvé pour "$query"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemBuilder: (context, index) {
        final receipt = results[index];
        final category = CategoryService.getCategoryById(receipt.category);

        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            title: Text(receipt.company),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('dd/MM/yyyy').format(receipt.date)),
                if (receipt.items.isNotEmpty)
                  Text(
                    '${receipt.items.length} items',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: Text(
              CurrencyFormatter.format(receipt.totalAmount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            onTap: () {
              close(context, null);
              onReceiptSelected(receipt);
            },
          ),
        );
      },
    );
  }
} 