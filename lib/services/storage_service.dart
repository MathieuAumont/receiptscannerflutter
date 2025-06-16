import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipt_scanner_flutter/models/receipt.dart';

class StorageService {
  static const String _receiptsKey = 'receipts';

  Future<List<Receipt>> getReceipts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final receiptsJson = prefs.getString(_receiptsKey);
      
      if (receiptsJson == null || receiptsJson.isEmpty) return [];
      
      // Vérifier que c'est bien une chaîne JSON valide
      final dynamic decoded = json.decode(receiptsJson);
      
      // S'assurer que c'est une liste
      if (decoded is! List) {
        print('Warning: Expected List but got ${decoded.runtimeType}');
        return [];
      }
      
      final List<dynamic> receiptsList = decoded;
      return receiptsList.map((json) {
        try {
          return Receipt.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing receipt: $e');
          return null;
        }
      }).where((receipt) => receipt != null).cast<Receipt>().toList();
    } catch (e) {
      print('Error loading receipts: $e');
      // En cas d'erreur, nettoyer les données corrompues
      await _clearCorruptedData();
      return [];
    }
  }

  Future<void> saveReceipt(Receipt receipt) async {
    try {
      final receipts = await getReceipts();
      receipts.add(receipt);
      await _saveReceipts(receipts);
    } catch (e) {
      throw Exception('Failed to save receipt: $e');
    }
  }

  Future<void> updateReceipt(Receipt receipt) async {
    try {
      final receipts = await getReceipts();
      final index = receipts.indexWhere((r) => r.id == receipt.id);
      
      if (index != -1) {
        receipts[index] = receipt;
        await _saveReceipts(receipts);
      } else {
        throw Exception('Receipt not found');
      }
    } catch (e) {
      throw Exception('Failed to update receipt: $e');
    }
  }

  Future<void> deleteReceipt(String id) async {
    try {
      final receipts = await getReceipts();
      receipts.removeWhere((receipt) => receipt.id == id);
      await _saveReceipts(receipts);
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }

  Future<void> _saveReceipts(List<Receipt> receipts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final receiptsJson = json.encode(receipts.map((r) => r.toJson()).toList());
      await prefs.setString(_receiptsKey, receiptsJson);
    } catch (e) {
      throw Exception('Failed to save receipts: $e');
    }
  }

  Future<void> _clearCorruptedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_receiptsKey);
      print('Cleared corrupted data');
    } catch (e) {
      print('Error clearing corrupted data: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_receiptsKey);
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }
}