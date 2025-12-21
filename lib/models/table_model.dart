class TableModel {
  final String id;
  final String tableNumber;
  final int capacity;
  final String status;
  final String? location;
  final String? currentOrderId;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.status,
    this.location,
    this.currentOrderId,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      tableNumber: json['tableNumber'],
      capacity: json['capacity'],
      status: json['status'],
      location: json['location'],
      currentOrderId: json['currentOrderId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'capacity': capacity,
      'status': status,
      'location': location,
      'currentOrderId': currentOrderId,
    };
  }

  bool get isAvailable => status == 'Available';
  bool get isOccupied => status == 'Occupied';
}
