class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final int productCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    required this.productCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconName: json['iconName'],
      productCount: json['productCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'productCount': productCount,
    };
  }
}
