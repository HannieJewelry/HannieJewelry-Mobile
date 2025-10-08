class Cart {
  final String id;
  final Map<String, dynamic> attributes;
  final String? customerId;
  final int itemCount;
  final List<CartItem> items;
  final String? locationId;
  final String? note;
  final bool requiresShipping;
  final String token;
  final double totalPrice;
  final double totalWeight;

  Cart({
    required this.id,
    required this.attributes,
    this.customerId,
    required this.itemCount,
    required this.items,
    this.locationId,
    this.note,
    required this.requiresShipping,
    required this.token,
    required this.totalPrice,
    required this.totalWeight,
  });

  factory Cart.fromMap(Map<String, dynamic> map) {
    return Cart(
      id: map['id'] ?? '',
      attributes: Map<String, dynamic>.from(map['attributes'] ?? {}),
      customerId: map['customer_id'],
      itemCount: map['item_count'] ?? 0,
      items: List<CartItem>.from((map['items'] ?? []).map((item) => CartItem.fromMap(item))),
      locationId: map['location_id'],
      note: map['note'],
      requiresShipping: map['requires_shipping'] ?? false,
      token: map['token'] ?? '',
      totalPrice: (map['total_price'] is int) 
          ? (map['total_price'] as int).toDouble() 
          : (map['total_price'] ?? 0.0).toDouble(),
      totalWeight: (map['total_weight'] is int) 
          ? (map['total_weight'] as int).toDouble() 
          : (map['total_weight'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attributes': attributes,
      'customer_id': customerId,
      'item_count': itemCount,
      'items': items.map((item) => item.toMap()).toList(),
      'location_id': locationId,
      'note': note,
      'requires_shipping': requiresShipping,
      'token': token,
      'total_price': totalPrice,
      'total_weight': totalWeight,
    };
  }

  // Empty cart factory
  factory Cart.empty() {
    return Cart(
      id: '',
      attributes: {},
      itemCount: 0,
      items: [],
      requiresShipping: false,
      token: '',
      totalPrice: 0.0,
      totalWeight: 0.0,
    );
  }
}

class CartItem {
  final String id;
  final String? barcode;
  final bool giftCard;
  final double grams;
  final String handle;
  final String? image;
  final double linePrice;
  final double linePriceOriginal;
  final bool notAllowPromotion;
  final double price;
  final double priceOriginal;
  final String productId;
  final String productTitle;
  final String? productType;
  final Map<String, dynamic>? properties;
  int quantity;
  final bool requiresShipping;
  final String? sku;
  final String title;
  final String? url;
  final dynamic variantId; // Có thể là int hoặc string tùy từng API
  final String? variantTitle;
  final String? vendor;
  final List<String>? variantOptions;
  final String? variant; // Để tương thích ngược với code cũ
  final int? availableQuantity; // Maximum quantity available in stock
  final int line; // Line number in the cart

  CartItem({
    required this.id,
    this.barcode,
    this.giftCard = false,
    this.grams = 0,
    required this.handle,
    this.image,
    required this.linePrice,
    required this.linePriceOriginal,
    this.notAllowPromotion = false,
    required this.price,
    required this.priceOriginal,
    required this.productId,
    required this.productTitle,
    this.productType,
    this.properties,
    required this.quantity,
    this.requiresShipping = true,
    this.sku,
    required this.title,
    this.url,
    required this.variantId,
    this.variantTitle,
    this.vendor,
    this.variantOptions,
    this.variant,
    this.availableQuantity, // Add new parameter
    this.line = 1, // Default to line 1
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'gift_card': giftCard,
      'grams': grams,
      'handle': handle,
      'image': image,
      'line_price': linePrice,
      'line_price_original': linePriceOriginal,
      'not_allow_promotion': notAllowPromotion,
      'price': price,
      'price_original': priceOriginal,
      'product_id': productId,
      'product_title': productTitle,
      'product_type': productType,
      'properties': properties,
      'quantity': quantity,
      'requires_shipping': requiresShipping,
      'sku': sku,
      'title': title,
      'url': url,
      'variant_id': variantId,
      'variant_title': variantTitle,
      'vendor': vendor,
      'variant_options': variantOptions,
      'variant': variant,
      'available_quantity': availableQuantity, // Include in map
      'line': line, // Include line number
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final name = map['name'] ?? map['product_title'] ?? map['title'] ?? '';
    return CartItem(
      id: map['id'] ?? '',
      barcode: map['barcode'],
      giftCard: map['gift_card'] ?? false,
      grams: _toDouble(map['grams'] ?? 0),
      handle: map['handle'] ?? '',
      image: map['image'],
      linePrice: _toDouble(map['line_price'] ?? 0),
      linePriceOriginal: _toDouble(map['line_price_original'] ?? 0),
      notAllowPromotion: map['not_allow_promotion'] ?? false,
      price: _toDouble(map['price'] ?? 0),
      priceOriginal: _toDouble(map['price_original'] ?? 0),
      productId: map['product_id'] ?? '',
      productTitle: map['product_title'] ?? name,
      productType: map['product_type'],
      properties: map['properties'] != null 
          ? Map<String, dynamic>.from(map['properties'])
          : null,
      quantity: map['quantity'] ?? 1,
      requiresShipping: map['requires_shipping'] ?? true,
      sku: map['sku'],
      title: map['title'] ?? name,
      url: map['url'],
      variantId: map['variant_id'] ?? 0,
      variantTitle: map['variant_title'],
      vendor: map['vendor'],
      variantOptions: map['variant_options'] != null 
          ? List<String>.from(map['variant_options'])
          : null,
      variant: map['variant'] ?? map['variant_title'], // Tương thích ngược
      availableQuantity: map['available_quantity'] ?? map['inventory_quantity'] ?? 10, // Default to 10 for testing
      line: map['line'] ?? 1, // Get line number from map, default to 1 if missing
    );
  }
}

// Helper function to convert various types to double
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (_) {
      return 0.0;
    }
  }
  return 0.0;
}