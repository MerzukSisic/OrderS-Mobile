import 'package:orders_mobile/models/orders/selected_accompaniment.dart';

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
  final DateTime? updatedAt;
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
    this.updatedAt,
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
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      items: (json['items'] as List?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ?? [],
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
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  // ← DODANA copyWith METODA
  OrderModel copyWith({
    String? id,
    String? waiterId,
    String? waiterName,
    String? tableId,
    String? tableNumber,
    String? status,
    String? type,
    bool? isPartnerOrder,
    double? totalAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    List<OrderItem>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      status: status ?? this.status,
      type: type ?? this.type,
      isPartnerOrder: isPartnerOrder ?? this.isPartnerOrder,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      items: items ?? this.items,
    );
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
  final DateTime? createdAt;
  final List<SelectedAccompaniment> selectedAccompaniments;

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
    this.createdAt,
    this.selectedAccompaniments = const [],
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
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      selectedAccompaniments: (json['selectedAccompaniments'] as List?)
              ?.map((e) => SelectedAccompaniment.fromJson(e))
              .toList() ?? [],
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
      'createdAt': createdAt?.toIso8601String(),
      'selectedAccompaniments': selectedAccompaniments
          .map((e) => e.toJson())
          .toList(),
    };
  }

  List<String> get accompanimentIds => 
      selectedAccompaniments.map((e) => e.accompanimentId).toList();

  // ← DODANA copyWith METODA
  OrderItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? preparationLocation,
    int? quantity,
    double? unitPrice,
    double? subtotal,
    String? notes,
    String? status,
    DateTime? createdAt,
    List<SelectedAccompaniment>? selectedAccompaniments,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      preparationLocation: preparationLocation ?? this.preparationLocation,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      selectedAccompaniments: selectedAccompaniments ?? this.selectedAccompaniments,
    );
  }
}
