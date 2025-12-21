import 'package:flutter/material.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/tables/screens/tables_screen.dart';
import '../features/products/screens/products_screen.dart';
import '../features/products/screens/product_detail_screen.dart';
import '../features/orders/screens/checkout_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/admin/dashboard/screens/dashboard_screen.dart';
import '../features/admin/products/screens/admin_products_screen.dart';
import '../features/admin/products/screens/edit_product_screen.dart';
import '../features/admin/inventory/screens/inventory_screen.dart';
import '../features/admin/procurement/screens/procurement_screen.dart';
import '../features/admin/procurement/screens/procurement_checkout_screen.dart';
import '../features/admin/statistics/screens/statistics_screen.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class AppRouter {
  // Route names
  static const String initial = '/splash';
  static const String login = '/login';
  static const String tables = '/tables';
  static const String products = '/products';
  static const String productDetail = '/product-detail';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetail = '/order-detail';
  static const String profile = '/profile';

  // Admin routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static const String editProduct = '/admin/products/edit';
  static const String inventory = '/admin/inventory';
  static const String procurement = '/admin/procurement';
  static const String procurementCheckout = '/admin/procurement/checkout';
  static const String statistics = '/admin/statistics';

  // Routes map
  static Map<String, WidgetBuilder> get routes {
    return {
      '/splash': (context) => const SplashScreen(),
      '/login': (context) => const LoginScreen(),
      '/tables': (context) => const TablesScreen(),
      '/products': (context) => const ProductsScreen(),
      '/product-detail': (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args != null && args is ProductModel) {
          return ProductDetailScreen(product: args);
        }
        return const Scaffold(
          body: Center(child: Text('Product not found')),
        );
      },
      '/checkout': (context) => const CheckoutScreen(),
      '/orders': (context) => const OrdersScreen(),
      '/order-detail': (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args != null && args is OrderModel) {
          return OrderDetailScreen(order: args);
        }
        return const Scaffold(
          body: Center(child: Text('Order not found')),
        );
      },
      '/profile': (context) => const ProfileScreen(),
      '/admin/dashboard': (context) => const DashboardScreen(),
      '/admin/products': (context) => const AdminProductsScreen(),
      '/admin/products/edit': (context) => const EditProductScreen(),
      '/admin/inventory': (context) => const InventoryScreen(),
      '/admin/procurement': (context) => const ProcurementScreen(),
      '/admin/procurement/checkout': (context) =>
          const ProcurementCheckoutScreen(),
      '/admin/statistics': (context) => const StatisticsScreen(),
    };
  }

  // Navigate helpers
  static Future<dynamic> navigateTo(BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static Future<dynamic> navigateAndReplace(
      BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushReplacementNamed(context, routeName,
        arguments: arguments);
  }

  static Future<dynamic> navigateAndRemoveUntil(
      BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void goBack(BuildContext context, {dynamic result}) {
    Navigator.pop(context, result);
  }
}
