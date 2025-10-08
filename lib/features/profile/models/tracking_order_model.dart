class TrackingOrderModel {
  final String id;
  final String orderCode;
  final String orderNumber;
  final String name;
  final String email;
  final double totalPrice;
  final String financialStatus;
  final String fulfillmentStatus;
  final String orderProcessingStatus;
  final String? tags;
  final String? gateway;
  final String note;
  final String? source;
  final String? sourceName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String cartToken;
  final List<TrackingLineItem> lineItems;
  final List<dynamic>? timelines;

  TrackingOrderModel({
    required this.id,
    required this.orderCode,
    required this.orderNumber,
    required this.name,
    required this.email,
    required this.totalPrice,
    required this.financialStatus,
    required this.fulfillmentStatus,
    required this.orderProcessingStatus,
    this.tags,
    this.gateway,
    required this.note,
    this.source,
    this.sourceName,
    required this.createdAt,
    required this.updatedAt,
    required this.cartToken,
    required this.lineItems,
    this.timelines,
  });

  factory TrackingOrderModel.fromMap(Map<String, dynamic> map) {
    return TrackingOrderModel(
      id: map['id'] ?? '',
      orderCode: map['order_code'] ?? '',
      orderNumber: map['order_number'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      totalPrice: (map['total_price'] ?? 0).toDouble(),
      financialStatus: map['financial_status'] ?? '',
      fulfillmentStatus: map['fulfillment_status'] ?? '',
      orderProcessingStatus: map['order_processing_status'] ?? '',
      tags: map['tags'],
      gateway: map['gateway'],
      note: map['note'] ?? '',
      source: map['source'],
      sourceName: map['source_name'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      cartToken: map['cart_token'] ?? '',
      lineItems: (map['line_items'] as List<dynamic>?)
              ?.map((item) => TrackingLineItem.fromMap(item))
              .toList() ??
          [],
      timelines: map['timelines'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_code': orderCode,
      'order_number': orderNumber,
      'name': name,
      'email': email,
      'total_price': totalPrice,
      'financial_status': financialStatus,
      'fulfillment_status': fulfillmentStatus,
      'order_processing_status': orderProcessingStatus,
      'tags': tags,
      'gateway': gateway,
      'note': note,
      'source': source,
      'source_name': sourceName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cart_token': cartToken,
      'line_items': lineItems.map((item) => item.toMap()).toList(),
      'timelines': timelines,
    };
  }

  // Helper methods
  String get statusDisplayText {
    switch (orderProcessingStatus.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PROCESSING':
        return 'Processing';
      case 'SHIPPED':
        return 'Shipped';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return orderProcessingStatus;
    }
  }

  String get financialStatusDisplayText {
    switch (financialStatus.toUpperCase()) {
      case 'PENDING':
        return 'Pending Payment';
      case 'PAID':
        return 'Paid';
      case 'REFUNDED':
        return 'Refunded';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return financialStatus;
    }
  }

  String get fulfillmentStatusDisplayText {
    switch (fulfillmentStatus.toUpperCase()) {
      case 'UNFULFILLED':
        return 'Unfulfilled';
      case 'FULFILLED':
        return 'Fulfilled';
      case 'PARTIAL':
        return 'Partially Fulfilled';
      default:
        return fulfillmentStatus;
    }
  }

  String get formattedTotalPrice {
    return '${totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }

  String get formattedCreatedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  @override
  String toString() {
    return 'TrackingOrderModel(id: $id, orderCode: $orderCode, orderNumber: $orderNumber, name: $name, totalPrice: $totalPrice)';
  }
}

class TrackingLineItem {
  final String id;
  final int variantId;
  final String productId;
  final String productTitle;
  final String variantTitle;
  final double price;
  final int quantity;
  final double lineAmount;

  TrackingLineItem({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.productTitle,
    required this.variantTitle,
    required this.price,
    required this.quantity,
    required this.lineAmount,
  });

  factory TrackingLineItem.fromMap(Map<String, dynamic> map) {
    return TrackingLineItem(
      id: map['id'] ?? '',
      variantId: map['variant_id'] ?? 0,
      productId: map['product_id'] ?? '',
      productTitle: map['product_title'] ?? '',
      variantTitle: map['variant_title'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      lineAmount: (map['line_amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'variant_id': variantId,
      'product_id': productId,
      'product_title': productTitle,
      'variant_title': variantTitle,
      'price': price,
      'quantity': quantity,
      'line_amount': lineAmount,
    };
  }

  String get formattedPrice {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }

  String get formattedLineAmount {
    return '${lineAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }

  @override
  String toString() {
    return 'TrackingLineItem(id: $id, productTitle: $productTitle, quantity: $quantity, lineAmount: $lineAmount)';
  }
}
