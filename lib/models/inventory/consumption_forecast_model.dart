class ConsumptionForecastModel {
  final String storeProductId;
  final String storeProductName;
  final int currentStock;
  final double averageDailyConsumption;
  final int estimatedDaysUntilDepletion;
  final bool needsReorder;
  final String unit;

  ConsumptionForecastModel({
    required this.storeProductId,
    required this.storeProductName,
    required this.currentStock,
    required this.averageDailyConsumption,
    required this.estimatedDaysUntilDepletion,
    required this.needsReorder,
    required this.unit,
  });

  factory ConsumptionForecastModel.fromJson(Map<String, dynamic> json) {
    return ConsumptionForecastModel(
      storeProductId: json['storeProductId'],
      storeProductName: json['storeProductName'],
      currentStock: json['currentStock'],
      averageDailyConsumption: (json['averageDailyConsumption'] as num).toDouble(),
      estimatedDaysUntilDepletion: json['estimatedDaysUntilDepletion'],
      needsReorder: json['needsReorder'],
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeProductId': storeProductId,
      'storeProductName': storeProductName,
      'currentStock': currentStock,
      'averageDailyConsumption': averageDailyConsumption,
      'estimatedDaysUntilDepletion': estimatedDaysUntilDepletion,
      'needsReorder': needsReorder,
      'unit': unit,
    };
  }

  bool get isCritical => estimatedDaysUntilDepletion < 3;
  bool get isLow => estimatedDaysUntilDepletion < 7;
}
