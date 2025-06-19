import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:receipt_scanner_flutter/config/app_config.dart';

class FlinksService {
  static final String _baseUrl = 'https://sandbox.flinks.io/v3';
  static final String _customerId = dotenv.env['FLINKS_CUSTOMER_ID'] ?? '';
  static final String _apiUrl = AppConfig.apiBaseUrl;

  // Initier la connexion Flinks
  static Future<Map<String, dynamic>> initiateConnection() async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/api/flinks/initiate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customerId': _customerId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to initiate Flinks connection: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error initiating Flinks connection: $e');
    }
  }

  // Vérifier le statut de la connexion
  static Future<Map<String, dynamic>> checkConnectionStatus(String requestId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/api/flinks/status/$requestId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check connection status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking connection status: $e');
    }
  }

  // Récupérer les comptes connectés
  static Future<List<Map<String, dynamic>>> getConnectedAccounts() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/api/flinks/accounts'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['accounts'] ?? []);
      } else {
        throw Exception('Failed to get connected accounts: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting connected accounts: $e');
    }
  }

  // Synchroniser les transactions
  static Future<List<Map<String, dynamic>>> syncTransactions() async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/api/flinks/sync'),
        headers: {
          'Content-Type': 'application/json',
        },
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

  // Déconnecter un compte
  static Future<bool> disconnectAccount(String accountId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiUrl/api/flinks/accounts/$accountId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error disconnecting account: $e');
    }
  }

  // Convertir une transaction Flinks en Receipt
  static Map<String, dynamic> transactionToReceiptData(Map<String, dynamic> transaction) {
    final now = DateTime.now();
    final transactionDate = DateTime.tryParse(transaction['date'] ?? '') ?? now;
    final amount = (transaction['amount'] ?? 0.0).abs(); // Montant positif
    final merchant = transaction['description'] ?? 'Transaction carte';

    return {
      'id': '${now.millisecondsSinceEpoch}_flinks_${transaction['id'] ?? ''}',
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
      'category': 'other',
      'currency': 'CAD',
      'notes': 'Transaction importée automatiquement via Flinks',
      'metadata': {
        'processedAt': now.toIso8601String(),
        'ocrEngine': 'flinks',
        'version': '1.0',
        'confidence': 1.0,
        'flinksTransactionId': transaction['id'],
      },
    };
  }
}