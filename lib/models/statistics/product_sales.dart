class ProductSales {
  final String productId;
  final String productName;
  final String categoryName;
  final int quantitySold;
  final double revenue;
  final double percentage;

  ProductSales({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.quantitySold,
    required this.revenue,
    required this.percentage,
  });

  factory ProductSales.fromJson(Map<String, dynamic> json) {
    return ProductSales(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      categoryName: json['categoryName'] as String,
      quantitySold: json['quantitySold'] as int,
      revenue: (json['revenue'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'categoryName': categoryName,
      'quantitySold': quantitySold,
      'revenue': revenue,
      'percentage': percentage,
    };
  }
}
