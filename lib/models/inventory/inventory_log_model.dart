class InventoryLogModel {
  final String id;
  final String storeProductId;
  final String storeProductName;
  final int quantityChange;
  final String type;
  final String? reason;
  final DateTime createdAt;

  InventoryLogModel({
    required this.id,
    required this.storeProductId,
    required this.storeProductName,
    required this.quantityChange,
    required this.type,
    this.reason,
    required this.createdAt,
  });

  factory InventoryLogModel.fromJson(Map<String, dynamic> json) {
    return InventoryLogModel(
      id: json['id'],
      storeProductId: json['storeProductId'],
      storeProductName: json['storeProductName'],
      quantityChange: json['quantityChange'],
      type: json['type'],
      reason: json['reason'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeProductId': storeProductId,
      'storeProductName': storeProductName,
      'quantityChange': quantityChange,
      'type': type,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isIncrease => quantityChange > 0;
  bool get isDecrease => quantityChange < 0;
}
