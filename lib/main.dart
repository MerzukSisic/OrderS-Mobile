import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:orders_mobile/config/env_config.dart';
import 'package:orders_mobile/providers/business_providers.dart';
import 'package:orders_mobile/providers/procurement_payments_providers.dart';
import 'package:orders_mobile/providers/users_accompaniments_providers.dart';
import 'package:orders_mobile/providers/notification_recommendation_providers.dart'; // ✅ ADD THIS
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/navigation_service.dart';
import 'providers/auth_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/products_provider.dart';
import 'providers/tables_provider.dart';
import 'providers/categories_provider.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Stripe init
  Stripe.publishableKey =
      EnvConfig.stripePublishableKey;
  // ✅ MUST: scheme used for 3DS / redirect flows
  Stripe.urlScheme = 'orders';
  await Stripe.instance.applySettings();

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

  runApp(const OrdersApp());
}

class OrdersApp extends StatelessWidget {
  const OrdersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider(create: (_) => StorageService()),
        Provider(create: (_) => NavigationService()),

        // Auth & Core Providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => TablesProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),

        // Business Providers
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => StoresProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),

        // Users & Accompaniments Providers
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => AccompanimentsProvider()),

        // Procurement & Payments Providers
        ChangeNotifierProvider(create: (_) => ProcurementProvider()),
        ChangeNotifierProvider(create: (_) => PaymentsProvider()),

        // ✅ Notifications & Recommendations Providers
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
        ChangeNotifierProvider(create: (_) => ReceiptsProvider()),
      ],
      child: MaterialApp(
        title: 'OrderS',
        theme: AppTheme.darkTheme,
        navigatorKey: NavigationService.navigatorKey,
        onGenerateRoute: (settings) {
          final routeName = settings.name;
          final builder = routeName != null ? AppRouter.routes[routeName] : null;
          if (builder != null) {
            return MaterialPageRoute(builder: builder, settings: settings);
          }
          final fallbackBuilder = AppRouter.routes[AppRouter.initial];
          if (fallbackBuilder != null) {
            return MaterialPageRoute(builder: fallbackBuilder, settings: settings);
          }
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Route not found')),
            ),
            settings: settings,
          );
        },
        initialRoute: AppRouter.initial,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}