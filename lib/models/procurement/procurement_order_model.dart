class ProcurementOrderModel {
  final String id;
  final String storeId;
  final String storeName;
  final String supplier;
  final double totalAmount;
  final String status;
  final String? stripePaymentIntentId;
  final String? notes;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final List<ProcurementOrderItem> items;

  ProcurementOrderModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.supplier,
    required this.totalAmount,
    required this.status,
    this.stripePaymentIntentId,
    this.notes,
    required this.orderDate,
    this.deliveryDate,
    this.items = const [],
  });

  factory ProcurementOrderModel.fromJson(Map<String, dynamic> json) {
    return ProcurementOrderModel(
      id: json['id'],
      storeId: json['storeId'],
      storeName: json['storeName'],
      supplier: json['supplier'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'],
      stripePaymentIntentId: json['stripePaymentIntentId'],
      notes: json['notes'],
      orderDate: DateTime.parse(json['orderDate']),
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : null,
      items: (json['items'] as List?)
              ?.map((e) => ProcurementOrderItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'storeName': storeName,
      'supplier': supplier,
      'totalAmount': totalAmount,
      'status': status,
      'stripePaymentIntentId': stripePaymentIntentId,
      'notes': notes,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  bool get isPending => status == 'Pending';
  bool get isPaid => status == 'Paid';
  bool get isReceived => status == 'Received';
  bool get isCancelled => status == 'Cancelled';

  ProcurementOrderModel copyWith({
    String? id,
    String? storeId,
    String? storeName,
    String? supplier,
    double? totalAmount,
    String? status,
    String? stripePaymentIntentId,
    String? notes,
    DateTime? orderDate,
    DateTime? deliveryDate,
    List<ProcurementOrderItem>? items,
  }) {
    return ProcurementOrderModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      supplier: supplier ?? this.supplier,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      notes: notes ?? this.notes,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      items: items ?? this.items,
    );
  }
}

class ProcurementOrderItem {
  final String id;
  final String storeProductId;
  final String storeProductName;
  final int quantity;
  final int? receivedQuantity;
  final double unitCost;
  final double subtotal;

  ProcurementOrderItem({
    required this.id,
    required this.storeProductId,
    required this.storeProductName,
    required this.quantity,
    this.receivedQuantity,
    required this.unitCost,
    required this.subtotal,
  });

  factory ProcurementOrderItem.fromJson(Map<String, dynamic> json) {
    return ProcurementOrderItem(
      id: json['id'],
      storeProductId: json['storeProductId'],
      storeProductName: json['storeProductName'],
      quantity: json['quantity'],
      receivedQuantity: json['receivedQuantity'],
      unitCost: (json['unitCost'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeProductId': storeProductId,
      'storeProductName': storeProductName,
      'quantity': quantity,
      'receivedQuantity': receivedQuantity,
      'unitCost': unitCost,
      'subtotal': subtotal,
    };
  }

  bool get isFullyReceived => receivedQuantity == quantity;
  bool get isPartiallyReceived => receivedQuantity != null && receivedQuantity! < quantity;

  ProcurementOrderItem copyWith({
    String? id,
    String? storeProductId,
    String? storeProductName,
    int? quantity,
    int? receivedQuantity,
    double? unitCost,
    double? subtotal,
  }) {
    return ProcurementOrderItem(
      id: id ?? this.id,
      storeProductId: storeProductId ?? this.storeProductId,
      storeProductName: storeProductName ?? this.storeProductName,
      quantity: quantity ?? this.quantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      unitCost: unitCost ?? this.unitCost,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}
