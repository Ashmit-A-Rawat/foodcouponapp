// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodapp/screens/admin_create_user_screen.dart';
import 'package:foodapp/screens/admin_statistics_screen.dart';
import 'package:foodapp/screens/canteen_home_screen.dart';
import 'package:foodapp/screens/canteen_menu_management.dart';
import 'package:foodapp/screens/canteen_orders_screen.dart';
import 'package:foodapp/screens/canteen_reports_screen.dart';
import 'package:foodapp/screens/canteen_transactions_screen.dart';
import 'package:foodapp/screens/menu_screen.dart';
import 'package:foodapp/screens/my_orders_screen.dart';
import 'package:foodapp/screens/order_confirmation_screen.dart';
import 'package:foodapp/services/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/admin_home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  ApiService.navigatorKey = GlobalKey<NavigatorState>();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: ApiService.navigatorKey,
      title: 'Metro Food',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/menu': (context) => const MenuScreen(),
        '/my-orders': (context) => const MyOrdersScreen(),
        '/order-confirmation': (context) => const OrderConfirmationScreen(
              cartItems: [],
              totalAmount: 0,
            ),
        '/qr-scanner': (context) => const QRScannerScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/admin-home': (context) => const AdminHomeScreen(),
        '/admin-statistics': (context) => const AdminStatisticsScreen(),
        '/admin-create-user': (context) => const AdminCreateUserScreen(),
        '/canteen-home': (context) => const CanteenHomeScreen(),
        '/canteen-menu': (context) => const CanteenMenuManagement(),
        '/canteen-orders': (context) => const CanteenOrdersScreen(),
        '/canteen-transactions': (context) => const CanteenTransactionsScreen(),
        '/canteen-reports': (context) => const CanteenReportsScreen(),
      },
    );
  }
}