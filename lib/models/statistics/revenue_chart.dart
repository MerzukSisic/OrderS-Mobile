class RevenueChart {
  final List<RevenueDataPoint> data;
  final double totalRevenue;
  final int totalOrders;

  RevenueChart({
    required this.data,
    required this.totalRevenue,
    required this.totalOrders,
  });

  factory RevenueChart.fromJson(Map<String, dynamic> json) {
    return RevenueChart(
      data: (json['data'] as List)
          .map((e) => RevenueDataPoint.fromJson(e))
          .toList(),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalOrders: json['totalOrders'],
    );
  }
}

class RevenueDataPoint {
  final DateTime date;
  final double revenue;
  final int orderCount;

  RevenueDataPoint({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  factory RevenueDataPoint.fromJson(Map<String, dynamic> json) {
    return RevenueDataPoint(
      date: DateTime.parse(json['date']),
      revenue: (json['revenue'] as num).toDouble(),
      orderCount: json['orderCount'],
    );
  }
}
