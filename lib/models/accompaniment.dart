class Accompaniment {
  final String id;
  final String name;
  final double extraCharge;
  final String accompanimentGroupId;
  final int displayOrder;
  final bool isAvailable;

  Accompaniment({
    required this.id,
    required this.name,
    required this.extraCharge,
    required this.accompanimentGroupId,
    required this.displayOrder,
    required this.isAvailable,
  });

  factory Accompaniment.fromJson(Map<String, dynamic> json) {
    return Accompaniment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      extraCharge: (json['extraCharge'] ?? 0).toDouble(),
      accompanimentGroupId: json['accompanimentGroupId'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'extraCharge': extraCharge,
      'accompanimentGroupId': accompanimentGroupId,
      'displayOrder': displayOrder,
      'isAvailable': isAvailable,
    };
  }

  String get priceLabel {
    if (extraCharge == 0) return '';
    return '+${extraCharge.toStringAsFixed(2)} KM';
  }
}