class AppConstants {
  // App Info
  static const String appName = 'OrderS';
  static const String appVersion = '1.0.0';
  
  // Roles
  static const String roleAdmin = 'Admin';
  static const String roleWaiter = 'Waiter';
  static const String roleBartender = 'Bartender';
  
  // Order Types
  static const String orderTypeDineIn = 'DineIn';
  static const String orderTypeTakeAway = 'TakeAway';
  
  // Order Status
  static const String orderStatusPending = 'Pending';
  static const String orderStatusPreparing = 'Preparing';
  static const String orderStatusReady = 'Ready';
  static const String orderStatusCompleted = 'Completed';
  static const String orderStatusCancelled = 'Cancelled';
  
  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyUserData = 'user_data';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Animation Duration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
