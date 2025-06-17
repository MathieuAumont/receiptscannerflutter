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
  final Receipt? receipt;

  const ManualEntryScreen({
    super.key,
    this.receipt,
  });

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class ItemEntry {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController quantityController;

  ItemEntry({
    required this.nameController,
    required this.priceController,
    required this.quantityController,
  });

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }
}

class ItemEntryWidget extends StatelessWidget {
  final ItemEntry item;
  final VoidCallback onRemove;
  final bool showRemoveButton;

  const ItemEntryWidget({
    super.key,
    required this.item,
    required this.onRemove,
    required this.showRemoveButton,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.nameController,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('item_name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              if (showRemoveButton) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: item.priceController,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('price'),
                    border: const OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      // Vérifier s'il y a plus de 2 décimales
                      final parts = value.split('.');
                      if (parts.length > 1 && parts[1].length > 2) {
                        // Tronquer à 2 décimales
                        final truncated = '${parts[0]}.${parts[1].substring(0, 2)}';
                        item.priceController.value = TextEditingValue(
                          text: truncated,
                          selection: TextSelection.collapsed(offset: truncated.length),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: item.quantityController,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('quantity'),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _companyController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = CategoryService.getDefaultCategories().first.id;
  final List<ItemEntry> _items = [];
  
  bool _pricesIncludeTax = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.receipt != null) {
      _companyController.text = widget.receipt!.company;
      _notesController.text = widget.receipt!.notes ?? '';
      _selectedDate = widget.receipt!.date;
      _selectedCategory = widget.receipt!.category;
      _items.addAll(widget.receipt!.items.map((item) => ItemEntry(
        nameController: TextEditingController(text: item.name),
        priceController: TextEditingController(text: item.price.toString()),
        quantityController: TextEditingController(text: item.quantity.toString()),
      )));
    } else {
      _addItem();
    }

    // Ajouter les listeners pour les calculs automatiques
    for (var item in _items) {
      item.priceController.addListener(_updateCalculations);
      item.quantityController.addListener(_updateCalculations);
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.priceController.removeListener(_updateCalculations);
      item.quantityController.removeListener(_updateCalculations);
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    final newItem = ItemEntry(
      nameController: TextEditingController(),
      priceController: TextEditingController(),
      quantityController: TextEditingController(text: '1'),
    );
    
    // Ajouter les listeners pour le nouvel item
    newItem.priceController.addListener(_updateCalculations);
    newItem.quantityController.addListener(_updateCalculations);
    
    setState(() {
      _items.add(newItem);
    });
  }

  void _removeItem(int index) {
    setState(() {
      // Retirer les listeners avant de supprimer l'item
      _items[index].priceController.removeListener(_updateCalculations);
      _items[index].quantityController.removeListener(_updateCalculations);
      _items[index].dispose();
      _items.removeAt(index);
      _updateCalculations();
    });
  }

  void _updateCalculations() {
    if (mounted) {
      setState(() {
        // Force la mise à jour de l'interface
      });
    }
  }

  double _calculateSubtotal() {
    return _items.fold(0.0, (sum, item) {
      final price = double.tryParse(item.priceController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      final quantity = int.tryParse(item.quantityController.text) ?? 1;
      return sum + (price * quantity);
    });
  }

  double _calculateTPS() {
    if (!_pricesIncludeTax) {
      return _calculateSubtotal() * 0.05;
    }
    return 0.0;
  }

  double _calculateTVQ() {
    if (!_pricesIncludeTax) {
      return _calculateSubtotal() * 0.09975;
    }
    return 0.0;
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateTPS() + _calculateTVQ();
  }

  Future<void> _saveReceipt() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (_companyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.translate('enter_store_name')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final validItems = _items.where((item) => 
      item.nameController.text.trim().isNotEmpty && 
      item.priceController.text.trim().isNotEmpty
    ).toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.translate('add_at_least_one_item')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final uniqueId = widget.receipt?.id ?? '${now.millisecondsSinceEpoch}_${now.microsecond}_${_companyController.text.hashCode}';
      
      final receiptItems = validItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return ReceiptItem(
          id: widget.receipt?.items[entry.key].id ?? '${uniqueId}_item_$index',
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
        metadata: widget.receipt?.metadata ?? ReceiptMetadata(
          processedAt: DateTime.now(),
          ocrEngine: 'manual',
          version: '1.0',
          confidence: 1.0,
        ),
      );

      if (mounted) {
        final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
        if (widget.receipt != null) {
          await receiptProvider.updateReceipt(receipt);
        } else {
          await receiptProvider.addReceipt(receipt);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(languageProvider.translate(widget.receipt != null ? 'receipt_updated' : 'receipt_saved_success')),
              backgroundColor: Colors.green,
            ),
          );
          context.push('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.translate('error_saving_receipt')),
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
        title: Text(languageProvider.translate(widget.receipt != null ? 'edit_receipt' : 'add_receipt')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.push('/'),
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
                          languageProvider.translate('general_info'),
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
                              Text(languageProvider.translate('category_${category.id}')),
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
                              languageProvider.translate('prices_include_tax'),
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
                                  '${languageProvider.translate('item')} ${index + 1}',
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
                                  ),
                                ),
                                
                                const SizedBox(width: AppTheme.spacingS),
                                
                                // Quantity
                                Expanded(
                                  child: TextFormField(
                                    controller: item.quantityController,
                                    decoration: InputDecoration(
                                      labelText: languageProvider.translate('quantity'),
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
                          languageProvider.translate('summary'),
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
                          languageProvider.translate('notes_optional'),
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
                        hintText: languageProvider.translate('add_notes'),
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
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(languageProvider.translate('saving')),
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