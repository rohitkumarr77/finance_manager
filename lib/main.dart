import 'package:finance_manager/screens/report_screen.dart';
import 'package:finance_manager/services/them_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

// Import screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/transactions_screen.dart';

import 'screens/profile_screen.dart';

//  NEW: feature screens
import 'screens/budget_screen.dart';
import 'screens/recurring_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/payment_analytics_screen.dart';

// Import theme service


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load saved theme
  await ThemeService.instance.loadTheme();

  runApp(const FinanceManagerApp());
}

class FinanceManagerApp extends StatefulWidget {
  const FinanceManagerApp({Key? key}) : super(key: key);

  @override
  State<FinanceManagerApp> createState() => _FinanceManagerAppState();
}

class _FinanceManagerAppState extends State<FinanceManagerApp> {
  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    ThemeService.instance.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Manager',
      debugShowCheckedModeBanner: false,

      // Light Theme
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF667eea),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        useMaterial3: true,
      ),

      // Dark Theme
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF667eea),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1E1E1E),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        useMaterial3: true,
      ),

      // Use ThemeService to determine theme mode
      themeMode: ThemeService.instance.themeMode,

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/add-transaction': (context) => const AddTransactionScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/profile': (context) => const ProfileScreen(),
        //  NEW routes
        '/budget': (context) => const BudgetScreen(),
        '/recurring': (context) => const RecurringScreen(),
        '/goals': (context) => const GoalsScreen(),
        '/payment-analytics': (context) => const PaymentAnalyticsScreen(),
      },
    );
  }
}