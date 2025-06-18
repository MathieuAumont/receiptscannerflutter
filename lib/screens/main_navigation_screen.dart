import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (_router != router) {
      _router?.routerDelegate.removeListener(_handleRouteChange);
      _router = router;
      _router?.routerDelegate.addListener(_handleRouteChange);
      _updateSelectedIndexFromRoute();
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_handleRouteChange);
    super.dispose();
  }

  void _handleRouteChange() {
    _updateSelectedIndexFromRoute();
  }

  void _updateSelectedIndexFromRoute() {
    if (!mounted || _router == null) return;
    
    try {
      final location = _router!.routerDelegate.currentConfiguration.uri.path;
      
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
          return;
      }
      
      if (mounted && _selectedIndex != newIndex) {
        setState(() {
          _selectedIndex = newIndex;
        });
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
              ? const Color(0xFF1A202C)
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXLarge),
            topRight: Radius.circular(AppTheme.radiusXLarge),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, languageProvider.translate('home')),
                _buildNavItem(1, Icons.camera_alt_rounded, languageProvider.translate('scan'), isSpecial: true),
                _buildNavItem(2, Icons.add_rounded, languageProvider.translate('manual_entry')),
                _buildNavItem(3, Icons.account_balance_wallet_rounded, languageProvider.translate('budget')),
                _buildNavItem(4, Icons.bar_chart_rounded, languageProvider.translate('reports')),
                _buildNavItem(5, Icons.settings_rounded, languageProvider.translate('settings')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isSpecial = false}) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
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
                        AppTheme.primaryColor.withOpacity(0.15),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSpecial 
                  ? Colors.white
                  : isSelected 
                      ? AppTheme.primaryColor
                      : AppTheme.textTertiary,
              size: isSpecial ? 28 : 24,
            ),
            if (!isSpecial) ...[
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 6 : 0,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}