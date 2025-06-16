import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/models/receipt.dart';
import 'package:receipt_scanner_flutter/models/category.dart';
import 'package:receipt_scanner_flutter/utils/currency_formatter.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _companyController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'shopping';
  List<ItemEntry> _items = [];
  
  bool _pricesIncludeTax = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(ItemEntry(onChanged: _updateCalculations));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
        _updateCalculations();
      });
    }
  }

  void _updateCalculations() {
    setState(() {
      // Force rebuild to update calculations
    });
  }

  double _calculateSubtotal() {
    double total = 0.0;
    for (final item in _items) {
      final price = double.tryParse(item.priceController.text) ?? 0.0;
      final quantity = int.tryParse(item.quantityController.text) ?? 1;
      total += price * quantity;
    }
    
    if (_pricesIncludeTax) {
      return total / 1.14975;
    }
    
    return total;
  }

  double _calculateTPS() {
    return _calculateSubtotal() * 0.05;
  }

  double _calculateTVQ() {
    return _calculateSubtotal() * 0.09975;
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateTPS() + _calculateTVQ();
  }

  Future<void> _saveReceipt() async {
    final validItems = _items.where((item) => 
      item.nameController.text.isNotEmpty && 
      (double.tryParse(item.priceController.text) ?? 0.0) > 0
    ).toList();
    
    if (validItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez ajouter au moins un article avec un nom et un prix'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_companyController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer le nom du magasin'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final uniqueId = '${now.millisecondsSinceEpoch}_${now.microsecond}_${_companyController.text.hashCode}';
      
      final receiptItems = validItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return ReceiptItem(
          id: '${uniqueId}_item_$index',
          name: item.nameController.text.trim(),
          price: double.tryParse(item.priceController.text) ?? 0.0,
          quantity: int.tryParse(item.quantityController.text) ?? 1,
        );
      }).toList();
      
      final receipt = Receipt(
        id: uniqueId,
        company: _companyController.text.trim(),
        date: _selectedDate,
        items: receiptItems,
        subtotal: _calculateSubtotal(),
        taxes: Taxes(
          tps: _calculateTPS(),
          tvq: _calculateTVQ(),
        ),
        totalAmount: _calculateTotal(),
        category: _selectedCategory,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        metadata: ReceiptMetadata(
          processedAt: DateTime.now(),
          ocrEngine: 'manual',
          version: '1.0',
          confidence: 1.0,
        ),
      );

      if (mounted) {
        await Provider.of<ReceiptProvider>(context, listen: false).addReceipt(receipt);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reçu sauvegardé avec succès!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final categories = CategoryService.getDefaultCategories();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('add_receipt')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Information
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          'Informations générales',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    
                    // Date Picker
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                        title: Text(languageProvider.translate('date')),
                        subtitle: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null && mounted) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingM),
                    
                    // Store Name
                    TextFormField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: languageProvider.translate('store_name'),
                        prefixIcon: Icon(Icons.store, color: AppTheme.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingM),
                    
                    // Category Selection
                    Text(
                      languageProvider.translate('category'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Wrap(
                      spacing: AppTheme.spacingS,
                      children: categories.map((category) {
                        final isSelected = _selectedCategory == category.id;
                        
                        return FilterChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.icon),
                              const SizedBox(width: 4),
                              Text(category.name),
                            ],
                          ),
                          onSelected: (selected) {
                            if (mounted) {
                              setState(() {
                                _selectedCategory = category.id;
                              });
                            }
                          },
                          selectedColor: category.color.withOpacity(0.3),
                          checkmarkColor: category.color,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Items Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          languageProvider.translate('items'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(languageProvider.translate('add_item')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.spacingM),
                    
                    // Tax Toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Les prix incluent les taxes',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          Switch(
                            value: _pricesIncludeTax,
                            onChanged: (value) {
                              if (mounted) {
                                setState(() {
                                  _pricesIncludeTax = value;
                                });
                              }
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingM),
                    
                    // Items List
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final itemTotal = (double.tryParse(item.priceController.text) ?? 0.0) * 
                                      (int.tryParse(item.quantityController.text) ?? 1);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Article ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                if (itemTotal > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      CurrencyFormatter.format(itemTotal),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (_items.length > 1) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _removeItem(index),
                                    icon: Icon(
                                      Icons.delete,
                                      color: AppTheme.errorColor,
                                      size: 20,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            
                            const SizedBox(height: AppTheme.spacingS),
                            
                            // Item Name
                            TextFormField(
                              controller: item.nameController,
                              decoration: InputDecoration(
                                labelText: languageProvider.translate('item_name'),
                                prefixIcon: const Icon(Icons.shopping_bag, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: AppTheme.spacingS),
                            
                            Row(
                              children: [
                                // Price
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: item.priceController,
                                    decoration: InputDecoration(
                                      labelText: languageProvider.translate('price'),
                                      prefixText: '\$ ',
                                      prefixIcon: const Icon(Icons.attach_money, size: 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (value) => _updateCalculations(),
                                  ),
                                ),
                                
                                const SizedBox(width: AppTheme.spacingS),
                                
                                // Quantity
                                Expanded(
                                  child: TextFormField(
                                    controller: item.quantityController,
                                    decoration: InputDecoration(
                                      labelText: 'Qté',
                                      prefixIcon: const Icon(Icons.numbers, size: 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => _updateCalculations(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Summary Section
            Card(
              elevation: 3,
              color: AppTheme.primaryColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calculate, color: AppTheme.primaryColor),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          'Résumé',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            languageProvider.translate('subtotal'),
                            CurrencyFormatter.format(_calculateSubtotal()),
                          ),
                          const Divider(height: 20),
                          _buildSummaryRow(
                            languageProvider.translate('tps'),
                            CurrencyFormatter.format(_calculateTPS()),
                          ),
                          _buildSummaryRow(
                            languageProvider.translate('tvq'),
                            CurrencyFormatter.format(_calculateTVQ()),
                          ),
                          const Divider(height: 20, thickness: 2),
                          _buildSummaryRow(
                            languageProvider.translate('total'),
                            CurrencyFormatter.format(_calculateTotal()),
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Notes Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, color: AppTheme.primaryColor),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          'Notes (optionnel)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Ajouter des notes sur ce reçu...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingXL),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveReceipt,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 3,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Sauvegarde en cours...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save),
                          const SizedBox(width: 8),
                          Text(
                            languageProvider.translate('save'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class ItemEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  final VoidCallback? onChanged;

  ItemEntry({this.onChanged}) {
    nameController.addListener(() => onChanged?.call());
    priceController.addListener(() => onChanged?.call());
    quantityController.addListener(() => onChanged?.call());
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }
}