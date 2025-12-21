class OrderModel {
  final String id;
  final String waiterId;
  final String waiterName;
  final String? tableId;
  final String? tableNumber;
  final String status;
  final String type;
  final bool isPartnerOrder;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.waiterId,
    required this.waiterName,
    this.tableId,
    this.tableNumber,
    required this.status,
    required this.type,
    required this.isPartnerOrder,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    this.completedAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      waiterId: json['waiterId'],
      waiterName: json['waiterName'],
      tableId: json['tableId'],
      tableNumber: json['tableNumber'],
      status: json['status'],
      type: json['type'],
      isPartnerOrder: json['isPartnerOrder'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      items: (json['items'] as List?)?.map((e) => OrderItem.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'waiterId': waiterId,
      'waiterName': waiterName,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'status': status,
      'type': type,
      'isPartnerOrder': isPartnerOrder,
      'totalAmount': totalAmount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String preparationLocation;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;
  final String status;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.preparationLocation,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    required this.status,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['productId'],
      productName: json['productName'],
      preparationLocation: json['preparationLocation'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      notes: json['notes'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'preparationLocation': preparationLocation,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
      'notes': notes,
      'status': status,
    };
  }
}
