import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:farmacia/firebase_options.dart';
import 'package:farmacia/providers/auth_provider_firebase.dart';
import 'package:farmacia/providers/medication_provider_firebase.dart';
import 'package:farmacia/providers/shelf_provider_firebase.dart';
import 'package:farmacia/providers/sale_provider_firebase.dart';
import 'package:farmacia/providers/theme_provider.dart';
import 'package:farmacia/screens/splash_screen.dart';
import 'package:farmacia/screens/auth/login_screen.dart';
import 'package:farmacia/screens/auth/register_screen.dart';
import 'package:farmacia/screens/home/home_screen.dart';
import 'package:farmacia/screens/admin/admin_screen.dart';
import 'package:farmacia/screens/admin/admin_dashboard_screen.dart';
import 'package:farmacia/screens/admin/user_management_screen.dart';
import 'package:farmacia/screens/admin/reports/monthly_sales_screen.dart';
import 'package:farmacia/screens/admin/reports/sales_report_screen.dart';
import 'package:farmacia/screens/admin/reports/inventory_report_screen.dart';
import 'package:farmacia/screens/medication/medication_list_screen.dart';
import 'package:farmacia/screens/medication/medication_detail_screen.dart';
import 'package:farmacia/screens/medication/medication_form_screen.dart';
import 'package:farmacia/screens/sales/sales_screen.dart';
import 'package:farmacia/screens/sales/sale_detail_screen.dart';
import 'package:farmacia/screens/sales/new_sale_screen.dart';
import 'package:farmacia/screens/shelf/shelf_list_screen.dart';
import 'package:farmacia/screens/shelf/shelf_detail_screen.dart';
import 'package:farmacia/screens/shelf/shelf_form_screen.dart';
import 'package:farmacia/screens/profile/profile_screen.dart';
import 'package:farmacia/screens/settings/settings_screen.dart';
import 'package:farmacia/screens/expiring/expiring_medications_screen.dart';
import 'package:farmacia/screens/expiring/expiring_by_shelf_screen.dart';
import 'package:farmacia/screens/expiring/shelf_expiring_detail_screen.dart';
import 'package:farmacia/utils/app_theme.dart';
import 'package:farmacia/utils/currency_formatter.dart';
import 'package:farmacia/screens/admin/user_form_screen.dart';  // ejemplo


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('es_ES', null);
  await CurrencyFormatter.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProviderFirebase()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProviderFirebase()),
        ChangeNotifierProvider(create: (_) => ShelfProviderFirebase()),
        ChangeNotifierProxyProvider<MedicationProviderFirebase, SaleProviderFirebase>(
          create: (context) => SaleProviderFirebase(
            Provider.of<MedicationProviderFirebase>(context, listen: false),
          ),
          update: (context, medicationProvider, previous) => 
            previous ?? SaleProviderFirebase(medicationProvider),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Farmacia App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminScreen(),
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/admin/users': (context) => const UserManagementScreen(),
         '/admin/users/add': (context) => const UserFormScreen(),
        '/admin/reports/monthly-sales': (context) => const MonthlySalesScreen(),
        '/admin/reports/sales': (context) => const SalesReportScreen(),
        '/admin/reports/inventory': (context) => const InventoryReportScreen(),
        '/medications': (context) => const MedicationListScreen(),
        '/sales': (context) => const SalesScreen(),
        '/new-sale': (context) => const NewSaleScreen(),
        '/shelves': (context) => const ShelfListScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/expiring': (context) => const ExpiringMedicationsScreen(),
        '/expiring/by-shelf': (context) => const ExpiringByShelfScreen(),
      },
      onGenerateRoute: (settings) {
        // Manejo de rutas con argumentos
        if (settings.name == '/medication-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => MedicationDetailScreen(
              medicationId: args['medicationId'],
            ),
          );
        } else if (settings.name == '/sale-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => SaleDetailScreen(
              saleId: args['saleId'],
            ),
          );
        } else if (settings.name == '/shelf-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ShelfDetailScreen(
              shelfId: args['shelfId'],
            ),
          );
        } else if (settings.name == '/expiring/shelf-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ShelfExpiringDetailScreen(
              shelfId: args['shelfId'],
            ),
          );
        } else if (settings.name == '/admin/reports') {
          return MaterialPageRoute(
            builder: (context) => const SalesReportScreen(),
          );
        } else if (settings.name == '/medication-form') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => MedicationFormScreen(
              medicationId: args?['medicationId'],
            ),
          );
        } else if (settings.name == '/shelf-form') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => ShelfFormScreen(
              shelf: args?['shelf'], // Cambiado para recibir el objeto completo
            ),
          );
        }
        return null;
      },
    );
  }
}