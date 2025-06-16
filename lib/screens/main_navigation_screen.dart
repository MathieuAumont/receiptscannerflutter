import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget child;

  const MainNavigationScreen({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  String _currentLocation = '/';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndexFromRoute();
  }

  void _updateSelectedIndexFromRoute() {
    if (!mounted) return;
    
    try {
      final router = GoRouter.of(context);
      final location = router.routerDelegate.currentConfiguration.uri.path;
      
      if (_currentLocation != location) {
        _currentLocation = location;
        
        int newIndex = 0;
        switch (location) {
          case '/':
            newIndex = 0;
            break;
          case '/scan':
            newIndex = 1;
            break;
          case '/manual-entry':
            newIndex = 2;
            break;
          case '/budget':
            newIndex = 3;
            break;
          case '/reports':
            newIndex = 4;
            break;
          case '/settings':
            newIndex = 5;
            break;
          default:
            newIndex = 0;
        }
        
        if (mounted && _selectedIndex != newIndex) {
          setState(() {
            _selectedIndex = newIndex;
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating navigation index: $e');
    }
  }

  void _onNavItemTapped(int index) {
    if (!mounted || _selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    try {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/scan');
          break;
        case 2:
          context.go('/manual-entry');
          break;
        case 3:
          context.go('/budget');
          break;
        case 4:
          context.go('/reports');
          break;
        case 5:
          context.go('/settings');
          break;
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1F2937)
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusLarge),
            topRight: Radius.circular(AppTheme.radiusLarge),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.home, languageProvider.translate('home')),
                _buildNavItem(1, LucideIcons.camera, languageProvider.translate('scan'), isSpecial: true),
                _buildNavItem(2, LucideIcons.plus, languageProvider.translate('manual_entry')),
                _buildNavItem(3, LucideIcons.wallet, languageProvider.translate('budget')),
                _buildNavItem(4, LucideIcons.barChart3, languageProvider.translate('reports')),
                _buildNavItem(5, LucideIcons.settings, languageProvider.translate('settings')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isSpecial = false}) {
    final isSelected = _selectedIndex == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('nav_item_$index'), // Clé unique pour chaque bouton
        onTap: () => _onNavItemTapped(index),
        borderRadius: BorderRadius.circular(
          isSpecial ? AppTheme.radiusLarge : AppTheme.radiusMedium,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isSpecial ? AppTheme.spacingM : AppTheme.spacingS,
            vertical: AppTheme.spacingS,
          ),
          decoration: BoxDecoration(
            gradient: isSpecial 
                ? AppTheme.primaryGradient
                : isSelected 
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.primaryColor.withOpacity(0.05),
                        ],
                      )
                    : null,
            borderRadius: BorderRadius.circular(
              isSpecial ? AppTheme.radiusLarge : AppTheme.radiusMedium,
            ),
            boxShadow: isSpecial ? [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Icon(
            icon,
            color: isSpecial 
                ? Colors.white
                : isSelected 
                    ? AppTheme.primaryColor
                    : AppTheme.textTertiary,
            size: isSpecial ? 28 : 24,
          ),
        ),
      ),
    );
  }
}