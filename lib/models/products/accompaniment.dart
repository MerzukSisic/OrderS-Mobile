class Accompaniment {
  final String id;
  final String name;
  final double extraCharge;
  final String accompanimentGroupId;
  final int displayOrder;
  final bool isAvailable;
  final DateTime? createdAt;

  Accompaniment({
    required this.id,
    required this.name,
    required this.extraCharge,
    required this.accompanimentGroupId,
    required this.displayOrder,
    required this.isAvailable,
    this.createdAt,
  });

  factory Accompaniment.fromJson(Map<String, dynamic> json) {
    return Accompaniment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      extraCharge: (json['extraCharge'] ?? 0).toDouble(),
      accompanimentGroupId: json['accompanimentGroupId'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
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
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get priceLabel {
    if (extraCharge == 0) return '';
    return '+${extraCharge.toStringAsFixed(2)} KM';
  }

  // ← DODANA copyWith METODA
  Accompaniment copyWith({
    String? id,
    String? name,
    double? extraCharge,
    String? accompanimentGroupId,
    int? displayOrder,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return Accompaniment(
      id: id ?? this.id,
      name: name ?? this.name,
      extraCharge: extraCharge ?? this.extraCharge,
      accompanimentGroupId: accompanimentGroupId ?? this.accompanimentGroupId,
      displayOrder: displayOrder ?? this.displayOrder,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
