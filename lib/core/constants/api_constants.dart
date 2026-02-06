class ApiConstants {
  // Base URL - change for your environment
  // For Android emulator: use 10.0.2.2 instead of localhost
  // For physical device: use your computer's IP address (e.g., http://192.168.1.100:5220/api)
  static const String baseUrl = 'http://localhost:5220/api';

  // Auth Endpoints
  static const String login = '/Auth/login';
  static const String register = '/Auth/register';
  static const String validateToken = '/Auth/validate';
  static const String me = '/Auth/me'; // ← DODAJ
  static const String changePassword = '/Auth/change-password'; // ← DODAJ
  static const String refresh = '/Auth/refresh'; // ← DODAJ
  static const String logout = '/Auth/logout'; // ← DODAJ

  // Products & Categories
  static const String products = '/Products';
  static const String categories = '/Categories';
  
  // Orders
  static const String orders = '/Orders';
  static const String activeOrders = '/Orders/active';
  
  // Tables & Users
  static const String tables = '/Tables';
  static const String users = '/Users';

  // Inventory
  static const String inventory = '/Inventory/store-products';
  static const String lowStock = '/Inventory/low-stock';

  // Procurement
  static const String procurement = '/Procurement';
  static const String procurementPaymentIntent = '/Procurement/{id}/payment-intent';
  static const String procurementConfirmPayment = '/Procurement/{id}/confirm-payment';

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
