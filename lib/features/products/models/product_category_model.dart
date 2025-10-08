class ProductCategory {
  final String id;
  final String title;
  final String bodyHtml;
  final String handle;
  final String? imageUrl;
  final int itemsCount;
  final bool published;
  final String publishedAt;
  final String publishedScope;
  final String sortOrder;
  final String? templateSuffix;
  final String updatedAt;
  final String createdAt;

  ProductCategory({
    required this.id,
    required this.title,
    required this.bodyHtml,
    required this.handle,
    this.imageUrl,
    required this.itemsCount,
    required this.published,
    required this.publishedAt,
    required this.publishedScope,
    required this.sortOrder,
    this.templateSuffix,
    required this.updatedAt,
    required this.createdAt,
  });

  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      bodyHtml: map['body_html'] ?? '',
      handle: map['handle'] ?? '',
      imageUrl: map['image'] != null && map['image']['src'] != null ? map['image']['src'] : null,
      itemsCount: map['items_count'] ?? 0,
      published: map['published'] ?? false,
      publishedAt: map['published_at'] ?? '',
      publishedScope: map['published_scope'] ?? '',
      sortOrder: map['sort_order'] ?? '',
      templateSuffix: map['template_suffix'],
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
      'image': {
        'src': imageUrl,
      },
      'items_count': itemsCount,
      'published': published,
      'published_at': publishedAt,
      'published_scope': publishedScope,
      'sort_order': sortOrder,
      'template_suffix': templateSuffix,
      'updated_at': updatedAt,
      'created_at': createdAt,
    };
  }
}