import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final int todayOrders;
  final int activeTables;
  final int lowStockItems;
  final double todayVsYesterday; // ← DODANO
  final String trendIndicator; // ← DODANO (up/down/neutral)
  final List<TopProduct> topProducts;
  final List<WaiterPerformance> topWaiters;
  final List<StoreProduct> lowStockProducts;

  const DashboardStats({
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.todayOrders,
    required this.activeTables,
    required this.lowStockItems,
    required this.todayVsYesterday,
    required this.trendIndicator,
    this.topProducts = const [],
    this.topWaiters = const [],
    this.lowStockProducts = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        todayRevenue: (json['todayRevenue'] as num).toDouble(),
        weekRevenue: (json['weekRevenue'] as num).toDouble(),
        monthRevenue: (json['monthRevenue'] as num).toDouble(),
        todayOrders: json['todayOrders'] as int,
        activeTables: json['activeTables'] as int,
        lowStockItems: json['lowStockItems'] as int,
        todayVsYesterday: (json['todayVsYesterday'] as num).toDouble(),
        trendIndicator: json['trendIndicator'] as String,
        topProducts: (json['topProducts'] as List?)
                ?.map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        topWaiters: (json['topWaiters'] as List?)
                ?.map((e) => WaiterPerformance.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        lowStockProducts: (json['lowStockProducts'] as List?)
                ?.map((e) => StoreProduct.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  bool get isTrendingUp => trendIndicator == 'up';
  bool get isTrendingDown => trendIndicator == 'down';
  bool get isTrendNeutral => trendIndicator == 'neutral';

  @override
  List<Object?> get props => [
        todayRevenue,
        weekRevenue,
        monthRevenue,
        todayOrders,
        activeTables,
        lowStockItems,
        todayVsYesterday,
        trendIndicator,
        topProducts,
        topWaiters,
        lowStockProducts,
      ];
}

class TopProduct extends Equatable {
  final String productId;
  final String productName;
  final int quantitySold;
  final double revenue;

  const TopProduct({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) => TopProduct(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        quantitySold: json['quantitySold'] as int,
        revenue: (json['revenue'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [productId, productName, quantitySold, revenue];
}

class WaiterPerformance extends Equatable {
  final String waiterId;
  final String waiterName;
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;

  const WaiterPerformance({
    required this.waiterId,
    required this.waiterName,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
  });

  factory WaiterPerformance.fromJson(Map<String, dynamic> json) => WaiterPerformance(
        waiterId: json['waiterId'] as String,
        waiterName: json['waiterName'] as String,
        totalOrders: json['totalOrders'] as int,
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
        averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [waiterId, waiterName, totalOrders, totalRevenue, averageOrderValue];
}

class StoreProduct extends Equatable {
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

  const StoreProduct({
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

  factory StoreProduct.fromJson(Map<String, dynamic> json) => StoreProduct(
        id: json['id'] as String,
        storeId: json['storeId'] as String,
        storeName: json['storeName'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        purchasePrice: (json['purchasePrice'] as num).toDouble(),
        currentStock: json['currentStock'] as int,
        minimumStock: json['minimumStock'] as int,
        unit: json['unit'] as String,
        isLowStock: json['isLowStock'] as bool,
        lastRestocked: DateTime.parse(json['lastRestocked'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        storeId,
        storeName,
        name,
        description,
        purchasePrice,
        currentStock,
        minimumStock,
        unit,
        isLowStock,
        lastRestocked,
      ];
}
