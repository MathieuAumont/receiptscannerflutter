import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipt_scanner_flutter/services/plaid_service.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/models/receipt.dart';
import 'dart:convert';

class PlaidProvider extends ChangeNotifier {
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isSyncing = false;
  List<Map<String, dynamic>> _connectedAccounts = [];
  String? _lastSyncDate;
  String? _error;
  String? _linkToken;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isSyncing => _isSyncing;
  List<Map<String, dynamic>> get connectedAccounts => _connectedAccounts;
  String? get lastSyncDate => _lastSyncDate;
  String? get error => _error;
  String? get linkToken => _linkToken;

  PlaidProvider() {
    _loadConnectionStatus();
  }

  Future<void> _loadConnectionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isConnected = prefs.getBool('plaid_connected') ?? false;
      _lastSyncDate = prefs.getString('plaid_last_sync');
      
      final accountsJson = prefs.getString('plaid_accounts');
      if (accountsJson != null) {
        _connectedAccounts = List<Map<String, dynamic>>.from(
          jsonDecode(accountsJson)
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading Plaid connection status: $e');
    }
  }

  Future<void> _saveConnectionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('plaid_connected', _isConnected);
      if (_lastSyncDate != null) {
        await prefs.setString('plaid_last_sync', _lastSyncDate!);
      }
      await prefs.setString('plaid_accounts', jsonEncode(_connectedAccounts));
    } catch (e) {
      debugPrint('Error saving Plaid connection status: $e');
    }
  }

  Future<String?> createLinkToken() async {
    _isConnecting = true;
    _error = null;
    notifyListeners();

    try {
      // Générer un ID utilisateur unique (vous pouvez utiliser l'ID de votre système d'auth)
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await PlaidService.createLinkToken(userId);
      
      if (result['success'] == true) {
        _linkToken = result['link_token'];
        return _linkToken;
      } else {
        _error = result['message'] ?? 'Erreur lors de la création du token';
        return null;
      }
    } catch (e) {
      _error = 'Erreur de connexion: $e';
      return null;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<bool> exchangePublicToken(String publicToken) async {
    try {
      final result = await PlaidService.exchangePublicToken(publicToken);
      
      if (result['success'] == true) {
        _isConnected = true;
        await loadConnectedAccounts();
        await _saveConnectionStatus();
        return true;
      } else {
        _error = result['message'] ?? 'Erreur lors de l\'échange du token';
        return false;
      }
    } catch (e) {
      _error = 'Erreur lors de l\'échange du token: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadConnectedAccounts() async {
    try {
      _connectedAccounts = await PlaidService.getAccounts();
      await _saveConnectionStatus();
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des comptes: $e';
      notifyListeners();
    }
  }

  Future<void> syncTransactions(ReceiptProvider receiptProvider, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isConnected) return;

    _isSyncing = true;
    _error = null;
    notifyListeners();

    try {
      final transactions = await PlaidService.syncTransactions(
        startDate: startDate,
        endDate: endDate,
      );
      
      int importedCount = 0;
      
      for (final transaction in transactions) {
        // Vérifier si c'est une transaction d'achat valide
        if (!PlaidService.isValidPurchaseTransaction(transaction)) {
          continue;
        }
        
        // Vérifier si la transaction n'existe pas déjà
        final existingReceipt = receiptProvider.receipts.firstWhere(
          (receipt) => receipt.metadata?.originalText == transaction['transaction_id'],
          orElse: () => Receipt(
            id: '',
            company: '',
            date: DateTime.now(),
            items: [],
            subtotal: 0,
            taxes: Taxes(tps: 0, tvq: 0),
            totalAmount: 0,
            category: '',
          ),
        );

        if (existingReceipt.id.isEmpty) {
          // Créer un nouveau reçu à partir de la transaction
          final receiptData = PlaidService.transactionToReceiptData(transaction);
          final receipt = Receipt.fromJson(receiptData);
          await receiptProvider.addReceipt(receipt);
          importedCount++;
        }
      }

      _lastSyncDate = DateTime.now().toIso8601String();
      await _saveConnectionStatus();
      
      if (importedCount > 0) {
        _error = null; // Clear any previous errors on successful sync
      }
      
    } catch (e) {
      _error = 'Erreur lors de la synchronisation: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      final success = await PlaidService.removeItem(itemId);
      
      if (success) {
        _connectedAccounts.removeWhere((account) => account['item_id'] == itemId);
        
        if (_connectedAccounts.isEmpty) {
          _isConnected = false;
          _lastSyncDate = null;
        }
        
        await _saveConnectionStatus();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erreur lors de la déconnexion: $e';
      notifyListeners();
    }
  }

  Future<void> disconnectAll() async {
    try {
      // Récupérer tous les item_ids uniques
      final itemIds = _connectedAccounts
          .map((account) => account['item_id'])
          .toSet()
          .cast<String>();
      
      for (final itemId in itemIds) {
        await PlaidService.removeItem(itemId);
      }
      
      _isConnected = false;
      _connectedAccounts.clear();
      _lastSyncDate = null;
      _linkToken = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('plaid_connected');
      await prefs.remove('plaid_last_sync');
      await prefs.remove('plaid_accounts');
      
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la déconnexion: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Synchronisation automatique périodique
  Future<void> autoSync(ReceiptProvider receiptProvider) async {
    if (!_isConnected || _isSyncing) return;
    
    // Synchroniser seulement les 7 derniers jours pour éviter les doublons
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));
    
    await syncTransactions(receiptProvider, startDate: startDate, endDate: endDate);
  }
}