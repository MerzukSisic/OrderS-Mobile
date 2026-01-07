class SelectedAccompaniment {
  final String accompanimentId;
  final String name;
  final double extraCharge;

  SelectedAccompaniment({
    required this.accompanimentId,
    required this.name,
    required this.extraCharge,
  });

  factory SelectedAccompaniment.fromJson(Map<String, dynamic> json) {
    return SelectedAccompaniment(
      accompanimentId: json['accompanimentId'] ?? '',
      name: json['name'] ?? '',
      extraCharge: (json['extraCharge'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accompanimentId': accompanimentId,
      'name': name,
      'extraCharge': extraCharge,
    };
  }
}