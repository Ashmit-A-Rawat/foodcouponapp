import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodapp/screens/admin_create_user_screen.dart';
import 'package:foodapp/screens/admin_statistics_screen.dart';
import 'package:foodapp/screens/canteen_home_screen.dart';
import 'package:foodapp/screens/canteen_reports_screen.dart';
import 'package:foodapp/screens/canteen_transactions_screen.dart';
import 'package:foodapp/services/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/admin_home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  ApiService.navigatorKey = GlobalKey<NavigatorState>();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
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
        fontFamily: 'Poppins', // Optional: Add custom font
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/qr-scanner': (context) => QRScannerScreen(),
        '/transactions': (context) => TransactionsScreen(),
        '/admin-home': (context) => AdminHomeScreen(),
        '/admin-statistics': (context) => AdminStatisticsScreen(),  // NEW
        '/admin-create-user': (context) => AdminCreateUserScreen(), // NEW
        '/canteen-home': (context) => CanteenHomeScreen(),
        '/canteen-transactions': (context) => CanteenTransactionsScreen(),
        '/canteen-reports': (context) => CanteenReportsScreen(),
      },
    );
  }
}