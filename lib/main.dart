import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/theme_provider.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/providers/budget_provider.dart';
import 'package:receipt_scanner_flutter/providers/category_provider.dart';
import 'package:receipt_scanner_flutter/providers/flinks_provider.dart';
import 'package:receipt_scanner_flutter/screens/main_navigation_screen.dart';
import 'package:receipt_scanner_flutter/screens/receipt_details_screen.dart';
import 'package:receipt_scanner_flutter/screens/analysis_screen.dart';
import 'package:receipt_scanner_flutter/screens/custom_report_screen.dart';
import 'package:receipt_scanner_flutter/screens/home_screen.dart';
import 'package:receipt_scanner_flutter/screens/scan_screen.dart';
import 'package:receipt_scanner_flutter/screens/manual_entry_screen.dart';
import 'package:receipt_scanner_flutter/screens/budget_screen.dart';
import 'package:receipt_scanner_flutter/screens/reports_screen.dart';
import 'package:receipt_scanner_flutter/screens/settings_screen.dart';
import 'package:receipt_scanner_flutter/screens/bank_connection_screen.dart';
import 'package:receipt_scanner_flutter/models/receipt.dart';

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
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => FlinksProvider()),
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
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/scan',
          builder: (context, state) => const ScanScreen(),
        ),
        GoRoute(
          path: '/manual-entry',
          builder: (context, state) => ManualEntryScreen(receipt: state.extra as Receipt?),
        ),
        GoRoute(
          path: '/budget',
          builder: (context, state) => const BudgetScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
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
    GoRoute(
      path: '/bank-connection',
      builder: (context, state) => const BankConnectionScreen(),
    ),
  ],
);