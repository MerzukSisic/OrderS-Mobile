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
  final List<ProductIngredient> ingredients;

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
    this.ingredients = const [],
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
      ingredients: (json['ingredients'] as List?)
              ?.map((e) => ProductIngredient.fromJson(e))
              .toList() ??
          [],
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
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
    };
  }
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
