import 'package:equatable/equatable.dart';

// Store DTO
class Store extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final bool isActive;
  final bool isExternal;

  const Store({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.isActive = true,
    this.isExternal = false,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      location: json['address'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isExternal: json['isExternal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'location': location,
        'isActive': isActive,
        'isExternal': isExternal,
      };

  @override
  List<Object?> get props => [id, name, description, location, isActive, isExternal];
}

// Store Product DTO (for inventory management)
class StoreProductItem extends Equatable {
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

  const StoreProductItem({
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

  factory StoreProductItem.fromJson(Map<String, dynamic> json) {
    return StoreProductItem(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String?,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      currentStock: json['currentStock'] as int,
      minimumStock: json['minimumStock'] as int,
      unit: json['unit'] as String,
      isLowStock: json['isLowStock'] as bool? ?? false,
      lastRestocked: DateTime.parse(json['lastRestocked'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
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
      };

  // Helper: Get stock percentage
  double get stockPercentage {
    if (minimumStock == 0) return 100.0;
    return (currentStock / minimumStock * 100).clamp(0, 100);
  }

  // Helper: Get stock status
  String get stockStatus {
    if (currentStock == 0) return 'Nema na stanju';
    if (isLowStock) return 'Nisko stanje';
    return 'Na stanju';
  }

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