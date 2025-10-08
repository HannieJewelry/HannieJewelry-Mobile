class Product {
  final String id;
  final String title;
  final String bodyHtml;
  final String handle;
  final String productType;
  final String publishedAt;
  final String publishedScope;
  final String templateSuffix;
  final String vendor;
  final bool notAllowPromotion;
  final bool available;
  final String tags;
  final int soleQuantity;
  final List<ProductImage> images;
  final ProductImage? image;
  final List<ProductOption> options;
  final List<ProductVariant> variants;
  final String updatedAt;
  final String createdAt;

  Product({
    required this.id,
    required this.title,
    required this.bodyHtml,
    required this.handle,
    required this.productType,
    required this.publishedAt,
    required this.publishedScope,
    required this.templateSuffix,
    required this.vendor,
    required this.notAllowPromotion,
    required this.available,
    required this.tags,
    required this.soleQuantity,
    required this.images,
    this.image,
    required this.options,
    required this.variants,
    required this.updatedAt,
    required this.createdAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      bodyHtml: map['body_html'] ?? '',
      handle: map['handle'] ?? '',
      productType: map['product_type'] ?? '',
      publishedAt: map['published_at'] ?? '',
      publishedScope: map['published_scope'] ?? '',
      templateSuffix: map['template_suffix'] ?? '',
      vendor: map['vendor'] ?? '',
      notAllowPromotion: map['not_allow_promotion'] ?? false,
      available: map['available'] ?? false,
      tags: map['tags'] ?? '',
      soleQuantity: map['sole_quantity'] ?? 0,
      images: List<ProductImage>.from(
          (map['images'] ?? []).map((x) => ProductImage.fromMap(x))),
      image: map['image'] != null ? ProductImage.fromMap(map['image']) : null,
      options: List<ProductOption>.from(
          (map['options'] ?? []).map((x) => ProductOption.fromMap(x))),
      variants: List<ProductVariant>.from(
          (map['variants'] ?? []).map((x) => ProductVariant.fromMap(x))),
      updatedAt: map['updated_at'] ?? '',
      createdAt: map['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body_html': bodyHtml,
      'handle': handle,
      'product_type': productType,
      'published_at': publishedAt,
      'published_scope': publishedScope,
      'template_suffix': templateSuffix,
      'vendor': vendor,
      'not_allow_promotion': notAllowPromotion,
      'available': available,
      'tags': tags,
      'sole_quantity': soleQuantity,
      'images': images.map((x) => x.toMap()).toList(),
      'image': image?.toMap(),
      'options': options.map((x) => x.toMap()).toList(),
      'variants': variants.map((x) => x.toMap()).toList(),
      'updated_at': updatedAt,
      'created_at': createdAt,
    };
  }

  // Get the price from the first variant or return 0 if no variants
  double get price {
    if (variants.isNotEmpty) {
      return variants.first.priceAsDouble;
    }
    return 0.0;
  }

  // Format price as VND currency
  String get formattedPrice {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}đ';
  }
}

class ProductImage {
  final String id;
  final String createdAt;
  final int position;
  final String productId;
  final String updatedAt;
  final String src;
  final String? alt;
  final List<String>? variantIds;

  ProductImage({
    required this.id,
    required this.createdAt,
    required this.position,
    required this.productId,
    required this.updatedAt,
    required this.src,
    this.alt,
    this.variantIds,
  });

  factory ProductImage.fromMap(Map<String, dynamic> map) {
    return ProductImage(
      id: map['id'] ?? '',
      createdAt: map['created_at'] ?? '',
      position: map['position'] ?? 0,
      productId: map['product_id'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      src: map['src'] ?? '',
      alt: map['alt'],
      variantIds: map['variant_ids'] != null 
          ? List<String>.from(map['variant_ids']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt,
      'position': position,
      'product_id': productId,
      'updated_at': updatedAt,
      'src': src,
      'alt': alt,
      'variant_ids': variantIds,
    };
  }
}

class ProductOption {
  final String name;
  final int position;
  final String productId;
  final List<String> values;

  ProductOption({
    required this.name,
    required this.position,
    required this.productId,
    required this.values,
  });

  factory ProductOption.fromMap(Map<String, dynamic> map) {
    return ProductOption(
      name: map['name'] ?? '',
      position: map['position'] ?? 0,
      productId: map['product_id'] ?? '',
      values: List<String>.from(map['values'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'product_id': productId,
      'values': values,
    };
  }
}

class ProductVariant {
  final int id;
  final String barcode;
  final String compareAtPrice;
  final String? createdAt;
  final String fulfillmentService;
  final int grams;
  final String? imageId;
  final String inventoryManagement;
  final String inventoryPolicy;
  final int inventoryQuantity;
  final int oldInventoryQuantity;
  final String option1;
  final String? option2;
  final String? option3;
  final int position;
  final String price;
  final String? productId;
  final bool requiresShipping;
  final String sku;
  final bool taxable;
  final String title;
  final String? updatedAt;
  final int weight;
  final bool available;
  final String weightUnit;

  ProductVariant({
    required this.id,
    required this.barcode,
    required this.compareAtPrice,
    this.createdAt,
    required this.fulfillmentService,
    required this.grams,
    this.imageId,
    required this.inventoryManagement,
    required this.inventoryPolicy,
    required this.inventoryQuantity,
    required this.oldInventoryQuantity,
    required this.option1,
    this.option2,
    this.option3,
    required this.position,
    required this.price,
    this.productId,
    required this.requiresShipping,
    required this.sku,
    required this.taxable,
    required this.title,
    this.updatedAt,
    required this.weight,
    required this.available,
    required this.weightUnit,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] ?? 0,
      barcode: map['barcode'] ?? '',
      compareAtPrice: map['compare_at_price'] ?? '0.0',
      createdAt: map['created_at'],
      fulfillmentService: map['fulfillment_service'] ?? '',
      grams: map['grams'] ?? 0,
      imageId: map['image_id'],
      inventoryManagement: map['inventory_management'] ?? '',
      inventoryPolicy: map['inventory_policy'] ?? '',
      inventoryQuantity: map['inventory_quantity'] ?? 0,
      oldInventoryQuantity: map['old_inventory_quantity'] ?? 0,
      option1: map['option1'] ?? '',
      option2: map['option2'],
      option3: map['option3'],
      position: map['position'] ?? 0,
      price: map['price'] ?? '0.0',
      productId: map['product_id'],
      requiresShipping: map['requires_shipping'] ?? false,
      sku: map['sku'] ?? '',
      taxable: map['taxable'] ?? false,
      title: map['title'] ?? '',
      updatedAt: map['updated_at'],
      weight: map['weight'] ?? 0,
      available: map['available'] ?? false,
      weightUnit: map['weight_unit'] ?? 'gram',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'compare_at_price': compareAtPrice,
      'created_at': createdAt,
      'fulfillment_service': fulfillmentService,
      'grams': grams,
      'image_id': imageId,
      'inventory_management': inventoryManagement,
      'inventory_policy': inventoryPolicy,
      'inventory_quantity': inventoryQuantity,
      'old_inventory_quantity': oldInventoryQuantity,
      'option1': option1,
      'option2': option2,
      'option3': option3,
      'position': position,
      'price': price,
      'product_id': productId,
      'requires_shipping': requiresShipping,
      'sku': sku,
      'taxable': taxable,
      'title': title,
      'updated_at': updatedAt,
      'weight': weight,
      'available': available,
      'weight_unit': weightUnit,
    };
  }

  // Get the price as a double
  double get priceAsDouble {
    return double.tryParse(price) ?? 0.0;
  }

  // Get the compareAtPrice as a double
  double get compareAtPriceAsDouble {
    return double.tryParse(compareAtPrice) ?? 0.0;
  }
}