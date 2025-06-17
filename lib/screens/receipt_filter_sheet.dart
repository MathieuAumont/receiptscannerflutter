import 'package:flutter/material.dart';
import 'package:receipt_scanner_flutter/models/category.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:provider/provider.dart';

class ReceiptFilterSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onFilterApplied;
  final Map<String, dynamic>? initialFilters;

  const ReceiptFilterSheet({
    super.key,
    required this.onFilterApplied,
    this.initialFilters,
  });

  @override
  State<ReceiptFilterSheet> createState() => _ReceiptFilterSheetState();
}

class _ReceiptFilterSheetState extends State<ReceiptFilterSheet> {
  final Set<String> _selectedCategories = {};
  DateTimeRange? _dateRange;
  RangeValues? _amountRange;
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      final filters = widget.initialFilters!;
      if (filters['categories'] != null) {
        _selectedCategories.addAll(List<String>.from(filters['categories']));
      }
      if (filters['dateRange'] != null) {
        _dateRange = filters['dateRange'] as DateTimeRange;
      }
      if (filters['amountRange'] != null) {
        _amountRange = filters['amountRange'] as RangeValues;
      }
      if (filters['sortBy'] != null) {
        _sortBy = filters['sortBy'] as String;
      }
      if (filters['sortAscending'] != null) {
        _sortAscending = filters['sortAscending'] as bool;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageProvider.translate('filter_receipts'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // Catégories
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageProvider.translate('categories'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Wrap(
                    spacing: AppTheme.spacingS,
                    children: CategoryService.getDefaultCategories().map((category) {
                      final isSelected = _selectedCategories.contains(category.id);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(category.name),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category.id);
                            } else {
                              _selectedCategories.remove(category.id);
                            }
                          });
                        },
                        avatar: Text(category.icon),
                        backgroundColor: category.color.withOpacity(0.1),
                        selectedColor: category.color.withOpacity(0.2),
                        checkmarkColor: category.color,
                        labelStyle: TextStyle(
                          color: isSelected ? category.color : AppTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  
                  // Période
                  Text(
                    languageProvider.translate('date_range'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _dateRange == null
                          ? languageProvider.translate('select_date_range')
                          : '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                    ),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _dateRange = picked);
                      }
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  
                  // Tri
                  Text(
                    languageProvider.translate('sort_by'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: _sortBy,
                        items: [
                          DropdownMenuItem(
                            value: 'date',
                            child: Text(languageProvider.translate('date')),
                          ),
                          DropdownMenuItem(
                            value: 'amount',
                            child: Text(languageProvider.translate('amount')),
                          ),
                          DropdownMenuItem(
                            value: 'company',
                            child: Text(languageProvider.translate('company')),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _sortBy = value);
                          }
                        },
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      IconButton(
                        icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                        onPressed: () {
                          setState(() => _sortAscending = !_sortAscending);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategories.clear();
                      _dateRange = null;
                      _amountRange = null;
                      _sortBy = 'date';
                      _sortAscending = false;
                    });
                    widget.onFilterApplied({});
                    Navigator.pop(context);
                  },
                  child: Text(languageProvider.translate('reset')),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onFilterApplied({
                      'categories': _selectedCategories.toList(),
                      'dateRange': _dateRange,
                      'amountRange': _amountRange,
                      'sortBy': _sortBy,
                      'sortAscending': _sortAscending,
                    });
                    Navigator.pop(context);
                  },
                  child: Text(languageProvider.translate('apply')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 