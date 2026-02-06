class CategorySales {
  final String categoryId;
  final String categoryName;
  final double revenue;
  final int orderCount;
  final double percentage;

  CategorySales({
    required this.categoryId,
    required this.categoryName,
    required this.revenue,
    required this.orderCount,
    required this.percentage,
  });

  factory CategorySales.fromJson(Map<String, dynamic> json) {
    return CategorySales(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      revenue: (json['revenue'] as num).toDouble(),
      orderCount: json['orderCount'] as int,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'revenue': revenue,
      'orderCount': orderCount,
      'percentage': percentage,
    };
  }
}
