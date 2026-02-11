import 'package:flutter/material.dart';
import 'package:orders_mobile/features/admin/categories/category_create_screen.dart';
import 'package:orders_mobile/features/admin/categories/category_edit_screen.dart';
import 'package:orders_mobile/features/admin/categories/category_list_screen.dart';
import 'package:orders_mobile/features/bar/screens/bar_order_screen.dart';
import 'package:orders_mobile/features/kitchen/screens/kitchen_orders_screen.dart';

// AUTH
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';

// TABLES
import '../features/tables/screens/tables_screen.dart';

// PRODUCTS
import '../features/products/screens/products_screen.dart';
import '../features/products/screens/product_detail_screen.dart';

// ORDERS
import '../features/orders/screens/checkout_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';

// BAR/KITCHEN

// PROFILE
import '../features/profile/screens/profile_screen.dart';

// ADMIN
import '../features/admin/dashboard/screens/dashboard_screen.dart';
import '../features/admin/products/screens/admin_products_screen.dart';
import '../features/admin/products/screens/admin_add_product_screen.dart';
import '../features/admin/products/screens/edit_product_screen.dart';
import '../features/admin/inventory/screens/inventory_screen.dart';
import '../features/admin/statistics/screens/statistics_screen.dart';
import '../features/admin/orders/screens/admin_orders_list_screen.dart';
import '../features/admin/orders/screens/admin_order_detail_screen.dart';

// USERS
import '../features/admin/users/screens/users_list_screen.dart';
import '../features/admin/users/screens/user_create_screen.dart';
import '../features/admin/users/screens/user_edit_screen.dart';

// PROCUREMENT
import '../features/admin/procurement/screens/procurement_list_screen.dart';
import '../features/admin/procurement/screens/admin_procurement_create_screen.dart';
import '../features/admin/procurement/screens/procurement_checkout_screen.dart';

// MODELS
import '../models/products/product_model.dart';
import '../models/orders/order_model.dart';

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
  static const String adminAddProduct = '/admin/products/add';
  static const String adminEditProduct = '/admin/products/edit';
  static const String inventory = '/admin/inventory';
  static const String adminStatistics = '/admin/statistics';

  // Users routes
  static const String usersList = '/admin/users';
  static const String userCreate = '/admin/users/create';
  static const String userEdit = '/admin/users/edit';

  // Procurement routes
  static const String procurementList = '/admin/procurement';
  static const String procurementCreate = '/admin/procurement/create';
  static const String procurementCheckout = '/admin/procurement/checkout';

  // Categories routes
  static const String categoriesList = '/admin/categories';
  static const String categoryCreate = '/admin/categories/create';
  static const String categoryEdit = '/admin/categories/edit';

  // Admin Orders routes
  static const String adminOrders = '/admin/orders';
  static const String adminOrderDetail = '/admin/orders/detail';

  // Bar/Kitchen routes
  static const String barOrders = '/bar/orders';
  static const String kitchenOrders = '/kitchen/orders';

  // Routes map
  static Map<String, WidgetBuilder> get routes {
    return {
      // AUTH
      initial: (_) => const SplashScreen(),
      login: (_) => const LoginScreen(),

      // MAIN
      tables: (_) => const TablesScreen(),
      products: (_) => const ProductsScreen(),

      productDetail: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is ProductModel) return ProductDetailScreen(product: args);
        return const _RouteError('Product not found');
      },

      checkout: (_) => const CheckoutScreen(),
      orders: (_) => const OrdersScreen(),

      orderDetail: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is OrderModel) return OrderDetailScreen(order: args);
        return const _RouteError('Order not found');
      },

      profile: (_) => const ProfileScreen(),

      // BAR/KITCHEN
      barOrders: (_) => const BarOrdersScreen(),
      kitchenOrders: (_) => const KitchenOrdersScreen(),

      // ADMIN
      adminDashboard: (_) => const DashboardScreen(),
      adminProducts: (_) => const AdminProductsScreen(),
      adminAddProduct: (_) => const AddProductScreen(),

      adminEditProduct: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String && args.isNotEmpty) {
          return EditProductScreen(productId: args);
        }
        return const _RouteError('Product ID not provided');
      },

      inventory: (_) => const InventoryScreen(),
      adminStatistics: (_) => const StatisticsScreen(),

      adminOrders: (_) => const AdminOrdersScreen(),
      
      adminOrderDetail: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is OrderModel) return AdminOrderDetailScreen(order: args);
        return const _RouteError('Order not found');
      },

      // USERS
      usersList: (_) => const UsersListScreen(),
      userCreate: (_) => const UserCreateScreen(),

      userEdit: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String && args.isNotEmpty) {
          return UserEditScreen(userId: args);
        }
        return const _RouteError('User ID not provided');
      },

      // PROCUREMENT
      procurementList: (_) => const AdminProcurementListScreen(),
      procurementCreate: (_) => const AdminProcurementCreateScreen(),

      procurementCheckout: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          return ProcurementCheckoutScreen(arguments: args);
        }
        return const _RouteError('Checkout arguments missing');
      },
      
      // CATEGORIES
      categoriesList: (_) => const CategoriesListScreen(),
      categoryCreate: (_) => const CategoryCreateScreen(),
      
      categoryEdit: (context) {
        final categoryId = ModalRoute.of(context)!.settings.arguments as String;
        return CategoryEditScreen(categoryId: categoryId);
      },
    };
  }

  // Navigate helpers
  static Future<dynamic> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static Future<dynamic> navigateAndReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static Future<dynamic> navigateAndRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
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

class _RouteError extends StatelessWidget {
  final String message;
  const _RouteError(this.message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(message)),
    );
  }
}