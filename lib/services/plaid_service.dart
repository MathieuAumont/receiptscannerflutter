import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:receipt_scanner_flutter/config/app_config.dart';

class PlaidService {
  static final String _apiUrl = AppConfig.apiBaseUrl;
  static final String _clientId = dotenv.env['PLAID_CLIENT_ID'] ?? '';
  static final String _secret = dotenv.env['PLAID_SECRET'] ?? '';
  static final String _environment = dotenv.env['PLAID_ENVIRONMENT'] ?? 'sandbox';

  // Créer un Link Token pour initier la connexion
  static Future<Map<String, dynamic>> createLinkToken(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/api/plaid/create-link-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'clientId': _clientId,
          'secret': _secret,
          'environment': _environment,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create link token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating link token: $e');
    }
  }

  // Échanger le public token contre un access token
  static Future<Map<String, dynamic>> exchangePublicToken(String publicToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/api/plaid/exchange-public-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'publicToken': publicToken,
          'clientId': _clientId,
          'secret': _secret,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to exchange public token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error exchanging public token: $e');
    }
  }

  // Récupérer les comptes connectés
  static Future<List<Map<String, dynamic>>> getAccounts() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/api/plaid/accounts'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['accounts'] ?? []);
      } else {
        throw Exception('Failed to get accounts: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting accounts: $e');
    }
  }

  // Synchroniser les transactions
  static Future<List<Map<String, dynamic>>> syncTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final response = await http.post(
        Uri.parse('$_apiUrl/api/plaid/transactions'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'startDate': start.toIso8601String().split('T')[0],
          'endDate': end.toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      } else {
        throw Exception('Failed to sync transactions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error syncing transactions: $e');
    }
  }

  // Supprimer un item (déconnecter un compte)
  static Future<bool> removeItem(String itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiUrl/api/plaid/item/$itemId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error removing item: $e');
    }
  }

  // Obtenir les informations d'une institution
  static Future<Map<String, dynamic>?> getInstitution(String institutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/api/plaid/institution/$institutionId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['institution'];
      }
      return null;
    } catch (e) {
      print('Error getting institution: $e');
      return null;
    }
  }

  // Convertir une transaction Plaid en Receipt
  static Map<String, dynamic> transactionToReceiptData(Map<String, dynamic> transaction) {
    final now = DateTime.now();
    final transactionDate = DateTime.tryParse(transaction['date'] ?? '') ?? now;
    final amount = (transaction['amount'] ?? 0.0).abs(); // Montant positif
    final merchant = transaction['merchant_name'] ?? 
                    transaction['name'] ?? 
                    'Transaction carte';

    // Déterminer la catégorie basée sur les catégories Plaid
    String category = 'other';
    final plaidCategories = transaction['category'] as List<dynamic>?;
    if (plaidCategories != null && plaidCategories.isNotEmpty) {
      final primaryCategory = plaidCategories[0].toString().toLowerCase();
      
      // Mapping des catégories Plaid vers nos catégories
      if (primaryCategory.contains('food') || primaryCategory.contains('restaurant')) {
        category = 'food';
      } else if (primaryCategory.contains('shop') || primaryCategory.contains('retail')) {
        category = 'shopping';
      } else if (primaryCategory.contains('transport') || primaryCategory.contains('gas')) {
        category = 'transport';
      } else if (primaryCategory.contains('entertainment') || primaryCategory.contains('recreation')) {
        category = 'entertainment';
      } else if (primaryCategory.contains('healthcare') || primaryCategory.contains('medical')) {
        category = 'health';
      } else if (primaryCategory.contains('home') || primaryCategory.contains('utilities')) {
        category = 'home';
      }
    }

    return {
      'id': '${now.millisecondsSinceEpoch}_plaid_${transaction['transaction_id'] ?? ''}',
      'company': merchant,
      'date': transactionDate.toIso8601String(),
      'items': [
        {
          'id': '${now.millisecondsSinceEpoch}_item_1',
          'name': 'Transaction carte',
          'price': amount,
          'quantity': 1,
        }
      ],
      'subtotal': amount,
      'taxes': {
        'tps': 0.0,
        'tvq': 0.0,
      },
      'totalAmount': amount,
      'category': category,
      'currency': transaction['iso_currency_code'] ?? 'CAD',
      'notes': 'Transaction importée automatiquement via Plaid\nCatégorie: ${plaidCategories?.join(', ') ?? 'Non spécifiée'}',
      'metadata': {
        'processedAt': now.toIso8601String(),
        'ocrEngine': 'plaid',
        'version': '1.0',
        'confidence': 1.0,
        'plaidTransactionId': transaction['transaction_id'],
        'plaidAccountId': transaction['account_id'],
      },
    };
  }

  // Vérifier si une transaction est un achat (et non un transfert/paiement)
  static bool isValidPurchaseTransaction(Map<String, dynamic> transaction) {
    final amount = transaction['amount'] as double?;
    final categories = transaction['category'] as List<dynamic>?;
    
    // Exclure les montants négatifs (crédits)
    if (amount == null || amount <= 0) return false;
    
    // Exclure les transferts et paiements
    if (categories != null) {
      final categoryString = categories.join(' ').toLowerCase();
      if (categoryString.contains('transfer') ||
          categoryString.contains('payment') ||
          categoryString.contains('deposit') ||
          categoryString.contains('withdrawal') ||
          categoryString.contains('fee')) {
        return false;
      }
    }
    
    return true;
  }
}