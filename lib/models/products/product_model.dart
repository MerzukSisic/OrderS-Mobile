import 'package:orders_mobile/models/products/accompaniment_group.dart';

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String categoryId;
  final String categoryName;
  final String? imageUrl;
  final bool isAvailable;
  final String preparationLocation;
  final int preparationTimeMinutes;
  final int stock;
  final DateTime? createdAt; 
  final DateTime? updatedAt; 
  final List<ProductIngredient> ingredients;
  final List<AccompanimentGroup> accompanimentGroups;
  final String? reason;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    this.imageUrl,
    required this.isAvailable,
    required this.preparationLocation,
    required this.preparationTimeMinutes,
    required this.stock,
    this.createdAt,
    this.updatedAt,
    this.ingredients = const [],
    this.accompanimentGroups = const [],
    this.reason,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'],
      preparationLocation: json['preparationLocation'],
      preparationTimeMinutes: json['preparationTimeMinutes'],
      stock: json['stock'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      ingredients: (json['ingredients'] as List?)
              ?.map((e) => ProductIngredient.fromJson(e))
              .toList() ??
          [],
      // ✅ DODANO: Mapiranje accompanimentGroups
      accompanimentGroups: (json['accompanimentGroups'] as List?)
              ?.map((e) => AccompanimentGroup.fromJson(e))
              .toList() ??
          [],
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'preparationLocation': preparationLocation,
      'preparationTimeMinutes': preparationTimeMinutes,
      'stock': stock,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'accompanimentGroups': accompanimentGroups.map((e) => e.toJson()).toList(), // ✅ DODANO
    };
  }

  // ✅ UPDATED copyWith - dodaj accompanimentGroups
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    bool? isAvailable,
    String? preparationLocation,
    int? preparationTimeMinutes,
    int? stock,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProductIngredient>? ingredients,
    List<AccompanimentGroup>? accompanimentGroups,
    String? reason,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      preparationLocation: preparationLocation ?? this.preparationLocation,
      preparationTimeMinutes: preparationTimeMinutes ?? this.preparationTimeMinutes,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ingredients: ingredients ?? this.ingredients,
      accompanimentGroups: accompanimentGroups ?? this.accompanimentGroups,
      reason: reason ?? this.reason,
    );
  }

  // ✅ DODANO: Helper metode za accompaniments
  bool get hasAccompaniments => accompanimentGroups.isNotEmpty;
  
  bool get hasRequiredAccompaniments => 
      accompanimentGroups.any((group) => group.isRequired);
  
  List<AccompanimentGroup> get requiredGroups => 
      accompanimentGroups.where((group) => group.isRequired).toList();
  
  List<AccompanimentGroup> get optionalGroups => 
      accompanimentGroups.where((group) => !group.isRequired).toList();
}

class ProductIngredient {
  final String id;
  final String storeProductId;
  final String storeProductName;
  final double quantity;
  final String unit;

  ProductIngredient({
    required this.id,
    required this.storeProductId,
    required this.storeProductName,
    required this.quantity,
    required this.unit,
  });

  factory ProductIngredient.fromJson(Map<String, dynamic> json) {
    return ProductIngredient(
      id: json['id'],
      storeProductId: json['storeProductId'],
      storeProductName: json['storeProductName'],
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeProductId': storeProductId,
      'storeProductName': storeProductName,
      'quantity': quantity,
      'unit': unit,
    };
  }
}