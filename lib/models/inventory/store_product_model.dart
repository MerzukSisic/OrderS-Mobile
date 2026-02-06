class StoreProductModel {
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
  final DateTime createdAt;

  StoreProductModel({
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
    required this.createdAt,
  });

  factory StoreProductModel.fromJson(Map<String, dynamic> json) {
    return StoreProductModel(
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
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'storeName': storeName,
      'name': name,
      'description': description,
      'purchasePrice': purchasePrice,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'unit': unit,
      'isLowStock': isLowStock,
      'lastRestocked': lastRestocked.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  StoreProductModel copyWith({
    String? id,
    String? storeId,
    String? storeName,
    String? name,
    String? description,
    double? purchasePrice,
    int? currentStock,
    int? minimumStock,
    String? unit,
    bool? isLowStock,
    DateTime? lastRestocked,
    DateTime? createdAt,
  }) {
    return StoreProductModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      name: name ?? this.name,
      description: description ?? this.description,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      unit: unit ?? this.unit,
      isLowStock: isLowStock ?? this.isLowStock,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
