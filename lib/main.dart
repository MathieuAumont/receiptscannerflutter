import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/theme_provider.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/providers/budget_provider.dart';
import 'package:receipt_scanner_flutter/screens/main_navigation_screen.dart';
import 'package:receipt_scanner_flutter/screens/receipt_details_screen.dart';
import 'package:receipt_scanner_flutter/screens/analysis_screen.dart';
import 'package:receipt_scanner_flutter/screens/custom_report_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ReceiptProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp.router(
            title: 'Receipt Scanner',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: languageProvider.locale,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigationScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox(), // Home content handled by MainNavigationScreen
        ),
        GoRoute(
          path: '/scan',
          builder: (context, state) => const SizedBox(), // Scan content handled by MainNavigationScreen
        ),
        GoRoute(
          path: '/manual-entry',
          builder: (context, state) => const SizedBox(), // Manual entry content handled by MainNavigationScreen
        ),
        GoRoute(
          path: '/budget',
          builder: (context, state) => const SizedBox(), // Budget content handled by MainNavigationScreen
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const SizedBox(), // Reports content handled by MainNavigationScreen
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SizedBox(), // Settings content handled by MainNavigationScreen
        ),
      ],
    ),
    GoRoute(
      path: '/receipt/:id',
      builder: (context, state) => ReceiptDetailsScreen(
        receiptId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/analysis',
      builder: (context, state) => const AnalysisScreen(),
    ),
    GoRoute(
      path: '/custom-report',
      builder: (context, state) => const CustomReportScreen(),
    ),
  ],
);