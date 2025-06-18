import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/models/receipt.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/models/category.dart';
import 'package:receipt_scanner_flutter/widgets/receipt_card.dart';
import 'package:receipt_scanner_flutter/providers/category_provider.dart';

class MonthlyReceiptsScreen extends StatelessWidget {
  final DateTime month;
  const MonthlyReceiptsScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final receiptProvider = Provider.of<ReceiptProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final receipts = receiptProvider.receipts.where((r) =>
      r.date.year == month.year && r.date.month == month.month
    ).toList();
    final categories = categoryProvider.categories;

    return Scaffold(
      appBar: AppBar(title: Text('Aperçu des factures')), // À traduire si besoin
      body: receipts.isEmpty
          ? Center(child: Text('Aucune facture pour ce mois'))
          : ListView.builder(
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                final category = categories.firstWhere(
                  (cat) => cat.id == receipt.category,
                  orElse: () => categories.first,
                );
                return ReceiptCard(receipt: receipt, category: category);
              },
            ),
    );
  }
} 