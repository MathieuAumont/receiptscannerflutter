import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  final _formKey = GlobalKey<FormState>();
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
      _items.add(ItemEntry());
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });
    }
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
    if (!_formKey.currentState!.validate()) return;
    
    final validItems = _items.where((item) => 
      item.nameController.text.isNotEmpty && 
      (double.tryParse(item.priceController.text) ?? 0.0) > 0
    ).toList();
    
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item with a name and price'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
      
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

      await Provider.of<ReceiptProvider>(context, listen: false).addReceipt(receipt);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving receipt: $e'),
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // General Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'General Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Date Picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(LucideIcons.calendar),
                        title: Text(languageProvider.translate('date')),
                        subtitle: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                      ),
                      
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Store Name
                      TextFormField(
                        controller: _companyController,
                        decoration: InputDecoration(
                          labelText: languageProvider.translate('store_name'),
                          prefixIcon: const Icon(LucideIcons.store),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the store name';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Category Selection
                      Text(
                        languageProvider.translate('category'),
                        style: Theme.of(context).textTheme.titleMedium,
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
                              setState(() {
                                _selectedCategory = category.id;
                              });
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
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languageProvider.translate('items'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(LucideIcons.plus),
                            label: Text(languageProvider.translate('add_item')),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Tax Toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Prices include tax'),
                        value: _pricesIncludeTax,
                        onChanged: (value) {
                          setState(() {
                            _pricesIncludeTax = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Items List
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        
                        return Container(
                          key: ValueKey('item_$index'),
                          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                          child: Row(
                            children: [
                              // Item Name
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: item.nameController,
                                  decoration: InputDecoration(
                                    labelText: languageProvider.translate('item_name'),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: AppTheme.spacingS),
                              
                              // Price
                              Expanded(
                                child: TextFormField(
                                  controller: item.priceController,
                                  decoration: InputDecoration(
                                    labelText: languageProvider.translate('price'),
                                    prefixText: '\$',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              
                              const SizedBox(width: AppTheme.spacingS),
                              
                              // Quantity
                              SizedBox(
                                width: 60,
                                child: TextFormField(
                                  controller: item.quantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Qty',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              
                              // Remove Button
                              if (_items.length > 1)
                                IconButton(
                                  onPressed: () => _removeItem(index),
                                  icon: Icon(
                                    LucideIcons.trash2,
                                    color: AppTheme.errorColor,
                                  ),
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
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      
                      _buildSummaryRow(
                        languageProvider.translate('subtotal'),
                        CurrencyFormatter.format(_calculateSubtotal()),
                      ),
                      _buildSummaryRow(
                        languageProvider.translate('tps'),
                        CurrencyFormatter.format(_calculateTPS()),
                      ),
                      _buildSummaryRow(
                        languageProvider.translate('tvq'),
                        CurrencyFormatter.format(_calculateTVQ()),
                      ),
                      const Divider(),
                      _buildSummaryRow(
                        languageProvider.translate('total'),
                        CurrencyFormatter.format(_calculateTotal()),
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingM),
              
              // Notes Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      alignLabelWithHint: true,
                      border: InputBorder.none,
                    ),
                    maxLines: 3,
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
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          languageProvider.translate('save'),
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXXL),
            ],
          ),
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
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

class ItemEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController(text: '0');
  final TextEditingController quantityController = TextEditingController(text: '1');

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }
}