import 'package:equatable/equatable.dart';

// Procurement Order DTO
class ProcurementOrder extends Equatable {
  final String id;
  final String storeId;
  final String storeName;
  final String supplier;
  final String status; // Pending, Paid, Shipped, Received, Cancelled
  final double totalAmount;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String? stripePaymentIntentId;
  final String? notes;
  final List<ProcurementOrderItem> items;

  const ProcurementOrder({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.supplier,
    required this.status,
    required this.totalAmount,
    required this.orderDate,
    this.deliveryDate,
    this.stripePaymentIntentId,
    this.notes,
    this.items = const [],
  });

  factory ProcurementOrder.fromJson(Map<String, dynamic> json) {
    return ProcurementOrder(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String? ?? '',
      supplier: json['supplier'] as String,
      status: json['status'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      orderDate: DateTime.parse(json['orderDate'] as String),
      deliveryDate: json['deliveryDate'] != null 
          ? DateTime.parse(json['deliveryDate'] as String) 
          : null,
      stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ProcurementOrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'storeName': storeName,
        'supplier': supplier,
        'status': status,
        'totalAmount': totalAmount,
        'orderDate': orderDate.toIso8601String(),
        'deliveryDate': deliveryDate?.toIso8601String(),
        'stripePaymentIntentId': stripePaymentIntentId,
        'notes': notes,
        'items': items.map((item) => item.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        id,
        storeId,
        storeName,
        supplier,
        status,
        totalAmount,
        orderDate,
        deliveryDate,
        stripePaymentIntentId,
        notes,
        items,
      ];
}

// Procurement Order Item DTO
class ProcurementOrderItem extends Equatable {
  final String id;
  final String storeProductId;
  final String storeProductName;
  final int quantity;
  final double unitCost;
  final double subtotal;
  final String? unit;

  const ProcurementOrderItem({
    required this.id,
    required this.storeProductId,
    required this.storeProductName,
    required this.quantity,
    required this.unitCost,
    required this.subtotal,
    this.unit,
  });

  factory ProcurementOrderItem.fromJson(Map<String, dynamic> json) {
    return ProcurementOrderItem(
      id: json['id'] as String,
      storeProductId: json['storeProductId'] as String,
      storeProductName: json['storeProductName'] as String? ?? '',
      quantity: json['quantity'] as int,
      unitCost: (json['unitCost'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeProductId': storeProductId,
        'storeProductName': storeProductName,
        'quantity': quantity,
        'unitCost': unitCost,
        'subtotal': subtotal,
        'unit': unit,
      };

  @override
  List<Object?> get props => [
        id,
        storeProductId,
        storeProductName,
        quantity,
        unitCost,
        subtotal,
        unit,
      ];
}

// Create Procurement DTO
class CreateProcurementDto {
  final String storeId;
  final String supplier;
  final String? notes;
  final List<CreateProcurementItemDto> items;

  const CreateProcurementDto({
    required this.storeId,
    required this.supplier,
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'storeId': storeId,
        'supplier': supplier,
        'notes': notes,
        'items': items.map((item) => item.toJson()).toList(),
      };
}

// Create Procurement Item DTO
class CreateProcurementItemDto {
  final String storeProductId;
  final int quantity;

  const CreateProcurementItemDto({
    required this.storeProductId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'storeProductId': storeProductId,
        'quantity': quantity,
      };
}

// Payment Intent Response
class PaymentIntentResponse {
  final String clientSecret;

  const PaymentIntentResponse({required this.clientSecret});

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      clientSecret: json['clientSecret'] as String,
    );
  }
}

// Confirm Payment DTO
class ConfirmPaymentDto {
  final String paymentIntentId;

  const ConfirmPaymentDto({required this.paymentIntentId});

  Map<String, dynamic> toJson() => {
        'paymentIntentId': paymentIntentId,
      };
}

// Procurement Status enum helper
class ProcurementStatus {
  static const String pending = 'Pending';
  static const String paid = 'Paid';
  static const String shipped = 'Shipped';
  static const String received = 'Received';
  static const String cancelled = 'Cancelled';

  static List<String> get allStatuses => [
        pending,
        paid,
        shipped,
        received,
        cancelled,
      ];

  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Na čekanju';
      case paid:
        return 'Plaćeno';
      case shipped:
        return 'Poslano';
      case received:
        return 'Primljeno';
      case cancelled:
        return 'Otkazano';
      default:
        return status;
    }
  }
}