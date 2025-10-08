class ProductImage {
  final String id;
  final int position;
  final String productId;
  final String src;
  final String? alt;
  final List<String>? variantIds;
  final String createdAt;
  final String updatedAt;

  ProductImage({
    required this.id,
    required this.position,
    required this.productId,
    required this.src,
    this.alt,
    this.variantIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductImage.fromMap(Map<String, dynamic> map) {
    return ProductImage(
      id: map['id'] ?? '',
      position: map['position'] ?? 0,
      productId: map['product_id'] ?? '',
      src: map['src'] ?? '',
      alt: map['alt'],
      variantIds: map['variant_ids'] != null 
          ? List<String>.from(map['variant_ids']) 
          : null,
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'position': position,
      'product_id': productId,
      'src': src,
      'alt': alt,
      'variant_ids': variantIds,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class ProductOption {
  final String id;
  final String name;
  final int position;
  final List<String> values;

  ProductOption({
    required this.id,
    required this.name,
    required this.position,
    required this.values,
  });

  factory ProductOption.fromMap(Map<String, dynamic> map) {
    return ProductOption(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      position: map['position'] ?? 0,
      values: List<String>.from(map['values'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'values': values,
    };
  }
}

class ProductVariant {
  final String id;
  final String productId;
  final String title;
  final String? option1;
  final String? option2;
  final String? option3;
  final String? sku;
  final int position;
  final String inventoryPolicy;
  final String fulfillmentService;
  final String inventoryManagement;
  final int inventoryQuantity;
  final double price;
  final double? compareAtPrice;
  final bool available;
  final String createdAt;
  final String updatedAt;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.title,
    this.option1,
    this.option2,
    this.option3,
    this.sku,
    required this.position,
    required this.inventoryPolicy,
    required this.fulfillmentService,
    required this.inventoryManagement,
    required this.inventoryQuantity,
    required this.price,
    this.compareAtPrice,
    required this.available,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] ?? '',
      productId: map['product_id'] ?? '',
      title: map['title'] ?? '',
      option1: map['option1'],
      option2: map['option2'],
      option3: map['option3'],
      sku: map['sku'],
      position: map['position'] ?? 0,
      inventoryPolicy: map['inventory_policy'] ?? '',
      fulfillmentService: map['fulfillment_service'] ?? '',
      inventoryManagement: map['inventory_management'] ?? '',
      inventoryQuantity: map['inventory_quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      compareAtPrice: map['compare_at_price']?.toDouble(),
      available: map['available'] ?? false,
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'title': title,
      'option1': option1,
      'option2': option2,
      'option3': option3,
      'sku': sku,
      'position': position,
      'inventory_policy': inventoryPolicy,
      'fulfillment_service': fulfillmentService,
      'inventory_management': inventoryManagement,
      'inventory_quantity': inventoryQuantity,
      'price': price,
      'compare_at_price': compareAtPrice,
      'available': available,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class ProductDetail {
  final String id;
  final String handle;
  final String title;
  final String bodyHtml;
  final String vendor;
  final String productType;
  final String tags;
  final String publishedScope;
  final String templateSuffix;
  final bool notAllowPromotion;
  final bool available;
  final int soleQuantity;
  final String createdAt;
  final String updatedAt;
  final String publishedAt;
  final List<ProductImage> images;
  final ProductImage? image;
  final List<ProductOption> options;
  final List<ProductVariant> variants;

  ProductDetail({
    required this.id,
    required this.handle,
    required this.title,
    required this.bodyHtml,
    required this.vendor,
    required this.productType,
    required this.tags,
    required this.publishedScope,
    required this.templateSuffix,
    required this.notAllowPromotion,
    required this.available,
    required this.soleQuantity,
    required this.createdAt,
    required this.updatedAt,
    required this.publishedAt,
    required this.images,
    this.image,
    required this.options,
    required this.variants,
  });

  factory ProductDetail.fromMap(Map<String, dynamic> map) {
    return ProductDetail(
      id: map['id'] ?? '',
      handle: map['handle'] ?? '',
      title: map['title'] ?? '',
      bodyHtml: map['body_html'] ?? '',
      vendor: map['vendor'] ?? '',
      productType: map['product_type'] ?? '',
      tags: map['tags'] ?? '',
      publishedScope: map['published_scope'] ?? '',
      templateSuffix: map['template_suffix'] ?? '',
      notAllowPromotion: map['not_allow_promotion'] ?? false,
      available: map['available'] ?? false,
      soleQuantity: map['sole_quantity'] ?? 0,
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      publishedAt: map['published_at'] ?? '',
      images: (map['images'] as List<dynamic>?)
          ?.map((item) => ProductImage.fromMap(item))
          .toList() ?? [],
      image: map['image'] != null ? ProductImage.fromMap(map['image']) : null,
      options: (map['options'] as List<dynamic>?)
          ?.map((item) => ProductOption.fromMap(item))
          .toList() ?? [],
      variants: (map['variants'] as List<dynamic>?)
          ?.map((item) => ProductVariant.fromMap(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'handle': handle,
      'title': title,
      'body_html': bodyHtml,
      'vendor': vendor,
      'product_type': productType,
      'tags': tags,
      'published_scope': publishedScope,
      'template_suffix': templateSuffix,
      'not_allow_promotion': notAllowPromotion,
      'available': available,
      'sole_quantity': soleQuantity,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'published_at': publishedAt,
      'images': images.map((image) => image.toMap()).toList(),
      'image': image?.toMap(),
      'options': options.map((option) => option.toMap()).toList(),
      'variants': variants.map((variant) => variant.toMap()).toList(),
    };
  }

  // Helper getters
  String get displayTitle => title.isNotEmpty ? title : handle;
  String get mainImageUrl => image?.src ?? (images.isNotEmpty ? images.first.src : '');
  bool get hasVariants => variants.isNotEmpty;
  bool get hasOptions => options.isNotEmpty;
  bool get hasImages => images.isNotEmpty;
  double get minPrice => variants.isNotEmpty 
      ? variants.map((v) => v.price).reduce((a, b) => a < b ? a : b)
      : 0.0;
  double get maxPrice => variants.isNotEmpty 
      ? variants.map((v) => v.price).reduce((a, b) => a > b ? a : b)
      : 0.0;
  String get priceRange => minPrice == maxPrice 
      ? '\$${minPrice.toStringAsFixed(2)}'
      : '\$${minPrice.toStringAsFixed(2)} - \$${maxPrice.toStringAsFixed(2)}';
}
