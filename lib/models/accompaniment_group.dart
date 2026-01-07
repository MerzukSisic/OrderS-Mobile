import 'accompaniment.dart';

class AccompanimentGroup {
  final String id;
  final String name;
  final String productId;
  final String selectionType; // 'Single' ili 'Multiple'
  final bool isRequired;
  final int? minSelections;
  final int? maxSelections;
  final int displayOrder;
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
      'accompaniments': accompaniments.map((a) => a.toJson()).toList(),
    };
  }

  bool get isSingleSelection => selectionType == 'Single';
  bool get isMultipleSelection => selectionType == 'Multiple';
}