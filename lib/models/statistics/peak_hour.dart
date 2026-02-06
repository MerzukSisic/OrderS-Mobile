class PeakHour {
  final int hour;
  final String timeRange;
  final int orderCount;
  final double revenue;
  final double averageOrderValue;

  PeakHour({
    required this.hour,
    required this.timeRange,
    required this.orderCount,
    required this.revenue,
    required this.averageOrderValue,
  });

  factory PeakHour.fromJson(Map<String, dynamic> json) {
    return PeakHour(
      hour: json['hour'] as int,
      timeRange: json['timeRange'] as String,
      orderCount: json['orderCount'] as int,
      revenue: (json['revenue'] as num).toDouble(),
      averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'timeRange': timeRange,
      'orderCount': orderCount,
      'revenue': revenue,
      'averageOrderValue': averageOrderValue,
    };
  }

  bool get isMorning => hour >= 6 && hour < 12;
  bool get isAfternoon => hour >= 12 && hour < 18;
  bool get isEvening => hour >= 18 && hour < 24;
  bool get isNight => hour >= 0 && hour < 6;
}
