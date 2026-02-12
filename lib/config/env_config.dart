class EnvConfig {
  // 🔧 STAVI SVOJU MAC IP ADRESU OVDJE:
  static const String _macIpAddress = '10.101.20.141'; // npr. '192.168.1.105'
  
  // API URLs
  static String get baseUrl {
    return 'http://$_macIpAddress:5220/api';
  }
  
  static String get signalRUrl {
    return 'http://$_macIpAddress:5220/hubs/orders';
  }

  static const String stripePublishableKey = 'pk_test_51QdZsNId2FRgVkuiAMWlpLmNHw4e4igDSx3DihjKQr4m2sz5DxNGJLFJPb48SIdPvHXeKl9IxvOV4IUvsrDjCywk00jLLh7syZ'; 
  static const String stripeTestKey = 'pk_test_51QdZsNId2FRgVkuiAMWlpLmNHw4e4igDSx3DihjKQr4m2sz5DxNGJLFJPb48SIdPvHXeKl9IxvOV4IUvsrDjCywk00jLLh7syZ'; 

}