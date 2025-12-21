class DashboardStats {
  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final int todayOrders;
  final int activeTables;
  final int lowStockItems;
  final List<TopProduct> topProducts;
  final List<WaiterPerformance> topWaiters;
  final List<StoreProduct> lowStockProducts;

  DashboardStats({
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.todayOrders,
    required this.activeTables,
    required this.lowStockItems,
    this.topProducts = const [],
    this.topWaiters = const [],
    this.lowStockProducts = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todayRevenue: (json['todayRevenue'] as num).toDouble(),
      weekRevenue: (json['weekRevenue'] as num).toDouble(),
      monthRevenue: (json['monthRevenue'] as num).toDouble(),
      todayOrders: json['todayOrders'],
      activeTables: json['activeTables'],
      lowStockItems: json['lowStockItems'],
      topProducts: (json['topProducts'] as List?)
              ?.map((e) => TopProduct.fromJson(e))
              .toList() ??
          [],
      topWaiters: (json['topWaiters'] as List?)
              ?.map((e) => WaiterPerformance.fromJson(e))
              .toList() ??
          [],
      lowStockProducts: (json['lowStockProducts'] as List?)
              ?.map((e) => StoreProduct.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TopProduct {
  final String productId;
  final String productName;
  final int quantitySold;
  final double revenue;

  TopProduct({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['productId'],
      productName: json['productName'],
      quantitySold: json['quantitySold'],
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class WaiterPerformance {
  final String waiterId;
  final String waiterName;
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;

  WaiterPerformance({
    required this.waiterId,
    required this.waiterName,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
  });

  factory WaiterPerformance.fromJson(Map<String, dynamic> json) {
    return WaiterPerformance(
      waiterId: json['waiterId'],
      waiterName: json['waiterName'],
      totalOrders: json['totalOrders'],
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
    );
  }
}

class StoreProduct {
  final String id;
  final String storeId;
  final String storeName;
  final String name;
  final String? description;
  final double purchasePrice;
  final int currentStock;
  final int minimumStock;
  final String unit;
  final bool isLowStock;
  final DateTime lastRestocked;

  StoreProduct({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.name,
    this.description,
    required this.purchasePrice,
    required this.currentStock,
    required this.minimumStock,
    required this.unit,
    required this.isLowStock,
    required this.lastRestocked,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['id'],
      storeId: json['storeId'],
      storeName: json['storeName'],
      name: json['name'],
      description: json['description'],
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      currentStock: json['currentStock'],
      minimumStock: json['minimumStock'],
      unit: json['unit'],
      isLowStock: json['isLowStock'],
      lastRestocked: DateTime.parse(json['lastRestocked']),
    );
  }
}
