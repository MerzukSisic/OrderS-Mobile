class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final int productCount;
  final DateTime? createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    required this.productCount,
    this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconName: json['iconName'],
      productCount: json['productCount'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'productCount': productCount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // ← DODANA copyWith METODA
  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    int? productCount,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
