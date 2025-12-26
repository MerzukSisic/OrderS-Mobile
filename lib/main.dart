import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orders_mobile/providers/inventory_provider.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/navigation_service.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/products_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/tables_provider.dart';
import 'routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const OrdersApp());
}

class OrdersApp extends StatelessWidget {
  const OrdersApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final storageService = StorageService();

    return MultiProvider(
      providers: [
        // Services
        Provider<ApiService>.value(value: apiService),
        Provider<StorageService>.value(value: storageService),
        Provider<NavigationService>(
          create: (_) => NavigationService(),
        ),

        // Providers
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductsProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => OrdersProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => TablesProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => InventoryProvider(apiService),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'OrderS',
            theme: AppTheme.darkTheme,
            navigatorKey: NavigationService.navigatorKey,
            onGenerateRoute: (settings) {
              final routeName = settings.name;
              final builder =
                  routeName != null ? AppRouter.routes[routeName] : null;

              if (builder != null) {
                return MaterialPageRoute(
                  builder: builder,
                  settings: settings,
                );
              }

              // Fallback to splash screen if route not found
              final fallbackBuilder = AppRouter.routes[AppRouter.initial];
              if (fallbackBuilder != null) {
                return MaterialPageRoute(
                  builder: fallbackBuilder,
                  settings: settings,
                );
              }

              // Ultimate fallback - should never reach here
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(child: Text('Route not found')),
                ),
                settings: settings,
              );
            },
            initialRoute: AppRouter.initial,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
