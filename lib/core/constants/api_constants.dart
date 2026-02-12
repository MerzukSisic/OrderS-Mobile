import 'package:orders_mobile/config/env_config.dart';

class ApiConstants {
  // Base URL - koristi EnvConfig umjesto hardcoded localhost
  static String get baseUrl => EnvConfig.baseUrl;
  static String get signalRUrl => EnvConfig.signalRUrl;
  
  // Auth Endpoints
  static const String login = '/Auth/login';
  static const String register = '/Auth/register';
  static const String validateToken = '/Auth/validate';
  static const String me = '/Auth/me';
  static const String changePassword = '/Auth/change-password';
  static const String refresh = '/Auth/refresh';
  static const String logout = '/Auth/logout';
  
  // Products & Categories
  static const String products = '/Products';
  static const String categories = '/Categories';
  
  // Orders
  static const String orders = '/Orders';
  static const String activeOrders = '/Orders/active';
  static String orderById(String id) => '/Orders/$id';
  static const String kitchenOrders = '/Orders/kitchen';
  static const String barOrders = '/Orders/bar';
  
  // Tables & Users
  static const String tables = '/Tables';
  static const String users = '/Users';
  
  // Inventory
  static const String inventory = '/Inventory/store-products';
  static const String lowStock = '/Inventory/low-stock';
  
  // Procurement
  static const String procurement = '/Procurement';
  static String procurementPaymentIntent(String id) => '/Procurement/$id/payment-intent';
  static String procurementConfirmPayment(String id) => '/Procurement/$id/confirm-payment';
  
  // Statistics
  static const String statistics = '/Statistics/dashboard';
  static const String dailyStats = '/Statistics/daily';
  
  // Notifications & Receipts
  static const String notifications = '/Notifications';
  static const String receipts = '/Receipts/customer';
  static const String kitchenReceipts = '/Receipts/kitchen';
  static const String barReceipts = '/Receipts/bar';
  
  // Recommendations
  static const String recommendations = '/Recommendations';
  static const String popularProducts = '/Recommendations/popular';
  
  // Timeout
  static const Duration timeout = Duration(seconds: 60);
}