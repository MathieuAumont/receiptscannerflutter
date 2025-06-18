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

class _ReceiptFilterSheetState extends State<ReceiptFilterSheet> with TickerProviderStateMixin {
  final Set<String> _selectedCategories = {};
  DateTimeRange? _dateRange;
  RangeValues? _amountRange;
  String _sortBy = 'date';
  bool _sortAscending = false;
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
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
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Fond semi-transparent avec animation
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withOpacity(0.3 * _fadeAnimation.value),
              ),
            ),
            
            // Sheet principal
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, MediaQuery.of(context).size.height * 0.7 * _slideAnimation.value),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Filtrer les reçus',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Contenu scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section Catégories
                              _buildSection(
                                title: 'Catégories',
                                icon: Icons.category,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: CategoryService.getDefaultCategories().map((category) {
                                    final isSelected = _selectedCategories.contains(category.id);
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedCategories.remove(category.id);
                                          } else {
                                            _selectedCategories.add(category.id);
                                          }
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: isSelected 
                                              ? LinearGradient(
                                                  colors: [category.color, category.color.withOpacity(0.8)],
                                                )
                                              : null,
                                          color: isSelected ? null : category.color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: category.color.withOpacity(isSelected ? 0.8 : 0.3),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected ? [
                                            BoxShadow(
                                              color: category.color.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ] : null,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              category.icon,
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              category.name,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : category.color,
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Section Période
                              _buildSection(
                                title: 'Période',
                                icon: Icons.date_range,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _dateRange != null ? AppTheme.primaryColor : Colors.grey[300]!,
                                      width: _dateRange != null ? 2 : 1,
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final picked = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                        initialDateRange: _dateRange,
                                      );
                                      if (picked != null) {
                                        setState(() => _dateRange = picked);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: _dateRange != null 
                                                ? AppTheme.primaryGradient
                                                : LinearGradient(
                                                    colors: [Colors.grey[400]!, Colors.grey[300]!],
                                                  ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.calendar_today,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _dateRange == null
                                                ? 'Sélectionner une période'
                                                : '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: _dateRange != null ? AppTheme.primaryColor : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        if (_dateRange != null)
                                          GestureDetector(
                                            onTap: () => setState(() => _dateRange = null),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red[100],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Icon(
                                                Icons.clear,
                                                size: 16,
                                                color: Colors.red[600],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Section Tri
                              _buildSection(
                                title: 'Trier par',
                                icon: Icons.sort,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceColor,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppTheme.primaryColor, width: 1),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: _sortBy,
                                                isExpanded: true,
                                                items: [
                                                  DropdownMenuItem(
                                                    value: 'date',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                                                        const SizedBox(width: 8),
                                                        const Text('Date'),
                                                      ],
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'amount',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.attach_money, size: 16, color: AppTheme.primaryColor),
                                                        const SizedBox(width: 8),
                                                        const Text('Montant'),
                                                      ],
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'company',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.store, size: 16, color: AppTheme.primaryColor),
                                                        const SizedBox(width: 8),
                                                        const Text('Magasin'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  if (value != null) {
                                                    setState(() => _sortBy = value);
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() => _sortAscending = !_sortAscending);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: _sortAscending ? AppTheme.primaryGradient : AppTheme.secondaryGradient,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (_sortAscending ? AppTheme.primaryColor : AppTheme.secondaryColor).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      
                      // Boutons d'action
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.primaryColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextButton(
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
                                  child: Text(
                                    'Réinitialiser',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextButton(
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
                                  child: const Text(
                                    'Appliquer les filtres',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}