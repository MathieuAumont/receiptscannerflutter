import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipt_scanner_flutter/services/flinks_service.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/models/receipt.dart';
import 'dart:convert';

class FlinksProvider extends ChangeNotifier {
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isSyncing = false;
  List<Map<String, dynamic>> _connectedAccounts = [];
  String? _lastSyncDate;
  String? _error;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isSyncing => _isSyncing;
  List<Map<String, dynamic>> get connectedAccounts => _connectedAccounts;
  String? get lastSyncDate => _lastSyncDate;
  String? get error => _error;

  FlinksProvider() {
    _loadConnectionStatus();
  }

  Future<void> _loadConnectionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isConnected = prefs.getBool('flinks_connected') ?? false;
      _lastSyncDate = prefs.getString('flinks_last_sync');
      
      final accountsJson = prefs.getString('flinks_accounts');
      if (accountsJson != null) {
        _connectedAccounts = List<Map<String, dynamic>>.from(
          jsonDecode(accountsJson)
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading Flinks connection status: $e');
    }
  }

  Future<void> _saveConnectionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('flinks_connected', _isConnected);
      if (_lastSyncDate != null) {
        await prefs.setString('flinks_last_sync', _lastSyncDate!);
      }
      await prefs.setString('flinks_accounts', jsonEncode(_connectedAccounts));
    } catch (e) {
      debugPrint('Error saving Flinks connection status: $e');
    }
  }

  Future<String?> initiateConnection() async {
    _isConnecting = true;
    _error = null;
    notifyListeners();

    try {
      final result = await FlinksService.initiateConnection();
      
      if (result['success'] == true) {
        return result['loginUrl']; // URL pour la connexion Flinks
      } else {
        _error = result['message'] ?? 'Erreur lors de l\'initiation de la connexion';
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

  Future<bool> checkConnectionStatus(String requestId) async {
    try {
      final result = await FlinksService.checkConnectionStatus(requestId);
      
      if (result['connected'] == true) {
        _isConnected = true;
        await loadConnectedAccounts();
        await _saveConnectionStatus();
        return true;
      }
      
      return false;
    } catch (e) {
      _error = 'Erreur lors de la vérification: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadConnectedAccounts() async {
    try {
      _connectedAccounts = await FlinksService.getConnectedAccounts();
      await _saveConnectionStatus();
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des comptes: $e';
      notifyListeners();
    }
  }

  Future<void> syncTransactions(ReceiptProvider receiptProvider) async {
    if (!_isConnected) return;

    _isSyncing = true;
    _error = null;
    notifyListeners();

    try {
      final transactions = await FlinksService.syncTransactions();
      
      for (final transaction in transactions) {
        // Vérifier si la transaction n'existe pas déjà
        final existingReceipt = receiptProvider.receipts.firstWhere(
          (receipt) => receipt.metadata?.originalText == transaction['id'],
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
          final receiptData = FlinksService.transactionToReceiptData(transaction);
          final receipt = Receipt.fromJson(receiptData);
          await receiptProvider.addReceipt(receipt);
        }
      }

      _lastSyncDate = DateTime.now().toIso8601String();
      await _saveConnectionStatus();
      
    } catch (e) {
      _error = 'Erreur lors de la synchronisation: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> disconnectAccount(String accountId) async {
    try {
      final success = await FlinksService.disconnectAccount(accountId);
      
      if (success) {
        _connectedAccounts.removeWhere((account) => account['id'] == accountId);
        
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
      for (final account in _connectedAccounts) {
        await FlinksService.disconnectAccount(account['id']);
      }
      
      _isConnected = false;
      _connectedAccounts.clear();
      _lastSyncDate = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('flinks_connected');
      await prefs.remove('flinks_last_sync');
      await prefs.remove('flinks_accounts');
      
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
}