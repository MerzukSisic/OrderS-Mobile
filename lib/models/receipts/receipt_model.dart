class CustomerReceiptModel {
  final String orderId;
  final String orderNumber;
  final String? tableNumber;
  final String waiterName;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String orderType;
  final String status;
  final bool isPartnerOrder;
  final List<ReceiptItemModel> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String? notes;

  CustomerReceiptModel({
    required this.orderId,
    required this.orderNumber,
    this.tableNumber,
    required this.waiterName,
    required this.createdAt,
    this.completedAt,
    required this.orderType,
    required this.status,
    required this.isPartnerOrder,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    this.notes,
  });

  factory CustomerReceiptModel.fromJson(Map<String, dynamic> json) {
    return CustomerReceiptModel(
      orderId: json['orderId'],
      orderNumber: json['orderNumber'],
      tableNumber: json['tableNumber'],
      waiterName: json['waiterName'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      orderType: json['orderType'],
      status: json['status'],
      isPartnerOrder: json['isPartnerOrder'] ?? false,
      items: (json['items'] as List)
          .map((item) => ReceiptItemModel.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      notes: json['notes'],
    );
  }
}

class ReceiptItemModel {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;
  final List<String> selectedAccompaniments;

  ReceiptItemModel({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    required this.selectedAccompaniments,
  });

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return ReceiptItemModel(
      productName: json['productName'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      notes: json['notes'],
      selectedAccompaniments: (json['selectedAccompaniments'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}

class KitchenReceiptModel {
  final String orderId;
  final String orderNumber;
  final String? tableNumber;
  final String waiterName;
  final DateTime createdAt;
  final String orderType;
  final List<KitchenReceiptItemModel> items;

  KitchenReceiptModel({
    required this.orderId,
    required this.orderNumber,
    this.tableNumber,
    required this.waiterName,
    required this.createdAt,
    required this.orderType,
    required this.items,
  });

  factory KitchenReceiptModel.fromJson(Map<String, dynamic> json) {
    return KitchenReceiptModel(
      orderId: json['orderId'],
      orderNumber: json['orderNumber'],
      tableNumber: json['tableNumber'],
      waiterName: json['waiterName'],
      createdAt: DateTime.parse(json['createdAt']),
      orderType: json['orderType'],
      items: (json['items'] as List)
          .map((item) => KitchenReceiptItemModel.fromJson(item))
          .toList(),
    );
  }
}

class KitchenReceiptItemModel {
  final String productName;
  final int quantity;
  final String? notes;
  final List<String> selectedAccompaniments;
  final List<String> ingredients;

  KitchenReceiptItemModel({
    required this.productName,
    required this.quantity,
    this.notes,
    required this.selectedAccompaniments,
    required this.ingredients,
  });

  factory KitchenReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return KitchenReceiptItemModel(
      productName: json['productName'],
      quantity: json['quantity'],
      notes: json['notes'],
      selectedAccompaniments: (json['selectedAccompaniments'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      ingredients: (json['ingredients'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}

class BarReceiptModel {
  final String orderId;
  final String orderNumber;
  final String? tableNumber;
  final String waiterName;
  final DateTime createdAt;
  final String orderType;
  final List<BarReceiptItemModel> items;

  BarReceiptModel({
    required this.orderId,
    required this.orderNumber,
    this.tableNumber,
    required this.waiterName,
    required this.createdAt,
    required this.orderType,
    required this.items,
  });

  factory BarReceiptModel.fromJson(Map<String, dynamic> json) {
    return BarReceiptModel(
      orderId: json['orderId'],
      orderNumber: json['orderNumber'],
      tableNumber: json['tableNumber'],
      waiterName: json['waiterName'],
      createdAt: DateTime.parse(json['createdAt']),
      orderType: json['orderType'],
      items: (json['items'] as List)
          .map((item) => BarReceiptItemModel.fromJson(item))
          .toList(),
    );
  }
}

class BarReceiptItemModel {
  final String productName;
  final int quantity;
  final String? notes;
  final List<String> selectedAccompaniments;

  BarReceiptItemModel({
    required this.productName,
    required this.quantity,
    this.notes,
    required this.selectedAccompaniments,
  });

  factory BarReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return BarReceiptItemModel(
      productName: json['productName'],
      quantity: json['quantity'],
      notes: json['notes'],
      selectedAccompaniments: (json['selectedAccompaniments'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}