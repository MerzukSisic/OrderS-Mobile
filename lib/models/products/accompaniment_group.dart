import 'accompaniment.dart';

class AccompanimentGroup {
  final String id;
  final String name;
  final String productId;
  final String selectionType;
  final bool isRequired;
  final int? minSelections;
  final int? maxSelections;
  final int displayOrder;
  final DateTime? createdAt; 
  final List<Accompaniment> accompaniments;

  AccompanimentGroup({
    required this.id,
    required this.name,
    required this.productId,
    required this.selectionType,
    required this.isRequired,
    this.minSelections,
    this.maxSelections,
    required this.displayOrder,
    this.createdAt,
    required this.accompaniments,
  });

  factory AccompanimentGroup.fromJson(Map<String, dynamic> json) {
    return AccompanimentGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      productId: json['productId'] ?? '',
      selectionType: json['selectionType'] ?? 'Single',
      isRequired: json['isRequired'] ?? false,
      minSelections: json['minSelections'],
      maxSelections: json['maxSelections'],
      displayOrder: json['displayOrder'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      accompaniments: (json['accompaniments'] as List<dynamic>?)
              ?.map((a) => Accompaniment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'productId': productId,
      'selectionType': selectionType,
      'isRequired': isRequired,
      'minSelections': minSelections,
      'maxSelections': maxSelections,
      'displayOrder': displayOrder,
      'createdAt': createdAt?.toIso8601String(),
      'accompaniments': accompaniments.map((a) => a.toJson()).toList(),
    };
  }

  bool get isSingleSelection => selectionType == 'Single';
  bool get isMultipleSelection => selectionType == 'Multiple';

  // ← DODANA copyWith METODA
  AccompanimentGroup copyWith({
    String? id,
    String? name,
    String? productId,
    String? selectionType,
    bool? isRequired,
    int? minSelections,
    int? maxSelections,
    int? displayOrder,
    DateTime? createdAt,
    List<Accompaniment>? accompaniments,
  }) {
    return AccompanimentGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      productId: productId ?? this.productId,
      selectionType: selectionType ?? this.selectionType,
      isRequired: isRequired ?? this.isRequired,
      minSelections: minSelections ?? this.minSelections,
      maxSelections: maxSelections ?? this.maxSelections,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      accompaniments: accompaniments ?? this.accompaniments,
    );
  }
}
