class TableModel {
  final String id;
  final String tableNumber;
  final int capacity;
  final String status;
  final String? location;
  final String? currentOrderId;
  final double? currentOrderTotal;    
  final int activeOrderCount;          

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.status,
    this.location,
    this.currentOrderId,
    this.currentOrderTotal,             
    this.activeOrderCount = 0,          
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      tableNumber: json['tableNumber'],
      capacity: json['capacity'],
      status: json['status'],
      location: json['location'],
      currentOrderId: json['currentOrderId'],
      currentOrderTotal: json['currentOrderTotal'] != null 
          ? (json['currentOrderTotal'] as num).toDouble() 
          : null,
      activeOrderCount: json['activeOrderCount'] ?? 0,
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
      'currentOrderTotal': currentOrderTotal,
      'activeOrderCount': activeOrderCount,
    };
  }

  bool get isAvailable => status == 'Available';
  bool get isOccupied => status == 'Occupied';
  bool get isReserved => status == 'Reserved';
  bool get hasActiveOrders => activeOrderCount > 0;

  // ← DODANA copyWith METODA
  TableModel copyWith({
    String? id,
    String? tableNumber,
    int? capacity,
    String? status,
    String? location,
    String? currentOrderId,
    double? currentOrderTotal,
    int? activeOrderCount,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      location: location ?? this.location,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      currentOrderTotal: currentOrderTotal ?? this.currentOrderTotal,
      activeOrderCount: activeOrderCount ?? this.activeOrderCount,
    );
  }
}
