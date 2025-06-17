import 'package:flutter/material.dart';
import 'package:receipt_scanner_flutter/models/receipt.dart';
import 'package:receipt_scanner_flutter/utils/currency_formatter.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/models/category.dart';

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

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Commencez à taper pour rechercher des reçus'),
      );
    }

    final results = receipts.where((receipt) {
      final searchLower = query.toLowerCase();
      final category = CategoryService.getCategoryById(receipt.category);
      return receipt.company.toLowerCase().contains(searchLower) ||
          receipt.notes?.toLowerCase().contains(searchLower) == true ||
          receipt.items.any((item) => item.name.toLowerCase().contains(searchLower)) ||
          category.name.toLowerCase().contains(searchLower);
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
            subtitle: Text(
              '${receipt.date.day}/${receipt.date.month}/${receipt.date.year}',
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