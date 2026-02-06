import 'package:orders_mobile/models/statistics/category_sales.dart';
import 'package:orders_mobile/models/statistics/dashboard_stats.dart';

class DailyStatistics {
  final DateTime date;
  final double totalRevenue;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double averageOrderValue;
  final List<TopProduct> topProducts;
  final List<CategorySales> categorySales;

  DailyStatistics({
    required this.date,
    required this.totalRevenue,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
    required this.topProducts,
    required this.categorySales,
  });

  factory DailyStatistics.fromJson(Map<String, dynamic> json) {
    return DailyStatistics(
      date: DateTime.parse(json['date']),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalOrders: json['totalOrders'],
      completedOrders: json['completedOrders'],
      cancelledOrders: json['cancelledOrders'],
      averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
      topProducts: (json['topProducts'] as List)
          .map((e) => TopProduct.fromJson(e))
          .toList(),
      categorySales: (json['categorySales'] as List)
          .map((e) => CategorySales.fromJson(e))
          .toList(),
    );
  }
}
