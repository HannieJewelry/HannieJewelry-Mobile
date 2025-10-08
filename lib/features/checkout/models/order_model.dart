class OrderItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'name': name,
      'image_url': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    try {
      // Extract product ID with fallbacks
      String productId = map['product_id'] ?? 
                         map['productId'] ?? 
                         map['id'] ?? 
                         'unknown';
      
      // Extract product name with fallbacks
      String name = map['name'] ?? 
                    map['product_name'] ?? 
                    map['productName'] ?? 
                    map['title'] ?? 
                    'Unknown Product';
      
      // Extract image URL with fallbacks
      String imageUrl = map['image_url'] ?? 
                        map['imageUrl'] ?? 
                        map['image'] ?? 
                        map['image_src'] ?? 
                        map['thumbnail'] ?? 
                        'assets/images/placeholder.png';
      
      // Extract price with type conversion
      double price = 0.0;
      var rawPrice = map['price'] ?? map['unit_price'] ?? map['unitPrice'] ?? 0;
      if (rawPrice is int) {
        price = rawPrice.toDouble();
      } else if (rawPrice is double) {
        price = rawPrice;
      } else if (rawPrice is String) {
        price = double.tryParse(rawPrice) ?? 0.0;
      }
      
      // Extract quantity with type conversion
      int quantity = 1;
      var rawQuantity = map['quantity'] ?? map['qty'] ?? 1;
      if (rawQuantity is int) {
        quantity = rawQuantity;
      } else if (rawQuantity is String) {
        quantity = int.tryParse(rawQuantity) ?? 1;
      }
      
      // If we have a product object, use its data
      if (map['product'] != null && map['product'] is Map<String, dynamic>) {
        final product = map['product'];
        productId = product['id'] ?? productId;
        name = product['name'] ?? name;
        imageUrl = product['image'] ?? imageUrl;
        
        if (product['price'] != null) {
          var productPrice = product['price'];
          if (productPrice is int) {
            price = productPrice.toDouble();
          } else if (productPrice is double) {
            price = productPrice;
          } else if (productPrice is String) {
            price = double.tryParse(productPrice) ?? price;
          }
        }
      }
      
      return OrderItem(
        productId: productId,
        name: name,
        imageUrl: imageUrl,
        price: price,
        quantity: quantity,
      );
    } catch (e) {
      print('❌ Error parsing order item: $e');
      print('❌ Order item data: $map');
      
      // Return a minimal valid item to prevent crashes
      return OrderItem(
        productId: 'error',
        name: 'Error loading product',
        imageUrl: 'assets/images/placeholder.png',
        price: 0,
        quantity: 1,
      );
    }
  }
}

enum DeliveryMethod { delivery, pickup }
enum PaymentMethod { cod, bankTransfer }

class OrderModel {
  final String id;
  final List<OrderItem> items;
  final double totalAmount;
  final double shippingFee;
  final DeliveryMethod deliveryMethod;
  final PaymentMethod paymentMethod;
  final String recipientName;
  final String recipientPhone;
  final String recipientAddress;
  final String? note;
  final String? pickupLocation;
  final DateTime? pickupTime;
  
  // Additional properties from API response
  final String? orderNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? financialStatus;
  final String? fulfillmentStatus;
  final String? orderProcessingStatus;
  final Map<String, dynamic>? shippingAddress;
  final List<Map<String, dynamic>>? noteAttributes;
  final List<Map<String, dynamic>>? shippingLines;

  OrderModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.shippingFee,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.recipientName,
    required this.recipientPhone,
    required this.recipientAddress,
    this.note,
    this.pickupLocation,
    this.pickupTime,
    this.orderNumber,
    required this.createdAt,
    required this.updatedAt,
    this.financialStatus,
    this.fulfillmentStatus,
    this.orderProcessingStatus,
    this.shippingAddress,
    this.noteAttributes,
    this.shippingLines,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => item.toMap()).toList(),
      'total_amount': totalAmount,
      'shipping_fee': shippingFee,
      'delivery_method': deliveryMethod.toString().split('.').last,
      'payment_method': paymentMethod.toString().split('.').last,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'recipient_address': recipientAddress,
      'note': note,
      'pickup_location': pickupLocation,
      'pickup_time': pickupTime?.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    // Handle different API response formats
    try {
      print('🔄 Converting order map: ${map.keys}');
      
      // Extract items properly from the map
      List<OrderItem> orderItems = [];
      if (map['items'] != null) {
        orderItems = (map['items'] as List)
            .map((item) => OrderItem.fromMap(item))
            .toList();
      } else if (map['order_items'] != null) {
        orderItems = (map['order_items'] as List)
            .map((item) => OrderItem.fromMap(item))
            .toList();
      } else if (map['orderItems'] != null) {
        orderItems = (map['orderItems'] as List)
            .map((item) => OrderItem.fromMap(item))
            .toList();
      } else if (map['line_items'] != null) {
        orderItems = (map['line_items'] as List)
            .map((item) => OrderItem.fromMap(item))
            .toList();
      }
      
      // Extract ID - prioritize actual UUID ID over order_number/order_code
      String orderId = 'unknown';
      if (map['id'] != null && map['id'].toString().isNotEmpty && !map['id'].toString().startsWith('#')) {
        orderId = map['id'].toString();
      } else if (map['order_id'] != null && map['order_id'].toString().isNotEmpty && !map['order_id'].toString().startsWith('#')) {
        orderId = map['order_id'].toString();
      } else if (map['orderId'] != null && map['orderId'].toString().isNotEmpty && !map['orderId'].toString().startsWith('#')) {
        orderId = map['orderId'].toString();
      } else {
        // Fallback to order_code/order_number only if no UUID ID is available
        orderId = map['order_code'] ?? map['order_number'] ?? 'unknown';
      }
      
      // Lấy note từ map
      String? note = map['note'];


      if (map['order_processing_status'] != null) {
        note = (note != null) ? "$note\norder_processing_status: ${map['order_processing_status']}" : "order_processing_status: ${map['order_processing_status']}";
      }


      // Thêm thông tin tags nếu có
      if (map['tags'] != null && map['tags'].toString().isNotEmpty) {
        note = (note != null) ? "$note\nTags: ${map['tags']}" : "Tags: ${map['tags']}";
      }
      
      // Thêm thông tin phương thức thanh toán
      if (map['gateway'] != null) {
        note = (note != null) ? "$note\nPayment: ${map['gateway']}" : "Payment: ${map['gateway']}";
      }
      
      // Extract tổng tiền với các kiểu dữ liệu khác nhau
      double total = 0.0;
      if (map['total_amount'] != null) {
        total = _parseDouble(map['total_amount']);
      } else if (map['total'] != null) {
        total = _parseDouble(map['total']);
      } else if (map['totalAmount'] != null) {
        total = _parseDouble(map['totalAmount']);
      } else if (map['total_price'] != null) {
        total = _parseDouble(map['total_price']);
      }
      
      // Extract phí vận chuyển với các kiểu dữ liệu khác nhau
      double shipping = 0.0;
      if (map['shipping_fee'] != null) {
        shipping = _parseDouble(map['shipping_fee']);
      } else if (map['shipping'] != null) {
        shipping = _parseDouble(map['shipping']);
      } else if (map['shippingFee'] != null) {
        shipping = _parseDouble(map['shippingFee']);
      }
      
      // Extract phương thức giao hàng
      DeliveryMethod delivery = DeliveryMethod.delivery;
      if (map['delivery_method'] != null) {
        delivery = map['delivery_method'].toString().toLowerCase() == 'pickup'
            ? DeliveryMethod.pickup
            : DeliveryMethod.delivery;
      } else if (map['deliveryMethod'] != null) {
        delivery = map['deliveryMethod'].toString().toLowerCase() == 'pickup'
            ? DeliveryMethod.pickup
            : DeliveryMethod.delivery;
      }
      
      // Extract phương thức thanh toán
      PaymentMethod payment = PaymentMethod.cod;
      if (map['payment_method'] != null) {
        payment = map['payment_method'].toString().toLowerCase() == 'banktransfer'
            ? PaymentMethod.bankTransfer
            : PaymentMethod.cod;
      } else if (map['paymentMethod'] != null) {
        payment = map['paymentMethod'].toString().toLowerCase() == 'banktransfer'
            ? PaymentMethod.bankTransfer
            : PaymentMethod.cod;
      } else if (map['gateway'] != null) {
        payment = map['gateway'].toString().toLowerCase().contains('cod')
            ? PaymentMethod.cod
            : PaymentMethod.bankTransfer;
      }
      
      // Extract thông tin người nhận - handle both string and map types
      String name = '';
      String phone = '';
      String address = '';
      
      // Handle name field
      var nameField = map['recipient_name'] ?? map['customer_name'] ?? map['customerName'] ?? map['name'];
      if (nameField is String) {
        name = nameField;
      } else if (nameField != null) {
        name = nameField.toString();
      }
      
      // Handle phone field  
      var phoneField = map['recipient_phone'] ?? map['customer_phone'] ?? map['customerPhone'] ?? map['phone'];
      if (phoneField is String) {
        phone = phoneField;
      } else if (phoneField != null) {
        phone = phoneField.toString();
      }
      
      // Handle address field - check if it's a map (shipping_address object)
      var addressField = map['recipient_address'] ?? map['shipping_address'] ?? map['shippingAddress'] ?? map['address'];
      if (addressField is String) {
        address = addressField;
      } else if (addressField is Map<String, dynamic>) {
        // If it's a shipping address object, extract the address string
        address = addressField['address1'] ?? addressField['address'] ?? addressField['line1'] ?? '';
        if (addressField['city'] != null) {
          address += ', ${addressField['city']}';
        }
        if (addressField['province'] != null) {
          address += ', ${addressField['province']}';
        }
      } else if (addressField != null) {
        address = addressField.toString();
      }
      
      // Nếu có product nhưng không có items
      if (orderItems.isEmpty && map['product'] != null) {
        final product = map['product'];
        orderItems = [
          OrderItem(
            productId: product['id'] ?? 'unknown',
            name: product['name'] ?? 'Unknown Product',
            imageUrl: product['image'] ?? 'assets/images/placeholder.png',
            price: _parseDouble(product['price']),
            quantity: map['quantity'] ?? 1,
          )
        ];
      }
      
      // Nếu có line_items nhưng không có items chi tiết
      if (orderItems.isEmpty && map['line_items'] != null && map['line_items'] is List && (map['line_items'] as List).isNotEmpty) {
        try {
          orderItems = (map['line_items'] as List).map((item) {
            return OrderItem(
              productId: item['product_id'] ?? item['id'] ?? 'unknown',
              name: item['product_title'] ?? item['title'] ?? item['variant_title'] ?? 'Product',
              imageUrl: item['image'] ?? 'assets/images/placeholder.png',
              price: _parseDouble(item['price']),
              quantity: item['quantity'] is num ? (item['quantity'] as num).toInt() : 1,
            );
          }).toList();
        } catch (e) {
          print('❌ Error parsing line items: $e');
        }
      }
      
      return OrderModel(
        id: orderId,
        items: orderItems,
        totalAmount: total,
        shippingFee: shipping,
        deliveryMethod: delivery,
        paymentMethod: payment,
        recipientName: name,
        recipientPhone: phone,
        recipientAddress: address,
        note: note,
        pickupLocation: map['pickup_location'] ?? map['pickupLocation'],
        pickupTime: map['pickup_time'] != null
            ? DateTime.parse(map['pickup_time'])
            : (map['pickupTime'] != null ? DateTime.parse(map['pickupTime']) : null),
        orderNumber: map['order_number'],
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
        financialStatus: map['financial_status'],
        fulfillmentStatus: map['fulfillment_status'],
        orderProcessingStatus: map['order_processing_status'],
        shippingAddress: map['shipping_address'],
        noteAttributes: map['note_attributes'] != null ? List<Map<String, dynamic>>.from(map['note_attributes']) : null,
        shippingLines: map['shipping_lines'] != null ? List<Map<String, dynamic>>.from(map['shipping_lines']) : null,
      );
    } catch (e) {
      print('❌ Error parsing order: $e');
      print('❌ Order data: $map');
      
      // Return order tối thiểu để tránh crash
      return OrderModel(
        id: map['id'] ?? map['order_code'] ?? map['order_number'] ?? 'error',
        items: [],
        totalAmount: 0,
        shippingFee: 0,
        deliveryMethod: DeliveryMethod.delivery,
        paymentMethod: PaymentMethod.cod,
        recipientName: '',
        recipientPhone: '',
        recipientAddress: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
  
  // Helper method to parse numeric values with different formats
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else {
      return 0.0;
    }
  }
}