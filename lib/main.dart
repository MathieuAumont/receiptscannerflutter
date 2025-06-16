import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/theme_provider.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/providers/budget_provider.dart';
import 'package:receipt_scanner_flutter/screens/main_navigation_screen.dart';
import 'package:receipt_scanner_flutter/screens/receipt_details_screen.dart';
import 'package:receipt_scanner_flutter/screens/analysis_screen.dart';
import 'package:receipt_scanner_flutter/screens/custom_report_screen.dart';
import 'package:receipt_scanner_flutter/config/app_config.dart';
import 'package:receipt_scanner_flutter/screens/home_screen.dart';
import 'package:receipt_scanner_flutter/screens/scan_screen.dart';
import 'package:receipt_scanner_flutter/screens/manual_entry_screen.dart';
import 'package:receipt_scanner_flutter/screens/budget_screen.dart';
import 'package:receipt_scanner_flutter/screens/reports_screen.dart';
import 'package:receipt_scanner_flutter/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    print('Environment loaded successfully');
  } catch (e) {
    print('Error loading .env file: $e');
  }
  
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
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/scan',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ScanScreen(),
          ),
        ),
        GoRoute(
          path: '/manual-entry',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ManualEntryScreen(),
          ),
        ),
        GoRoute(
          path: '/budget',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const BudgetScreen(),
          ),
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ReportsScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/receipt/:id',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: ReceiptDetailsScreen(
          receiptId: state.pathParameters['id']!,
        ),
      ),
    ),
    GoRoute(
      path: '/analysis',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const AnalysisScreen(),
      ),
    ),
    GoRoute(
      path: '/custom-report',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const CustomReportScreen(),
      ),
    ),
  ],
);