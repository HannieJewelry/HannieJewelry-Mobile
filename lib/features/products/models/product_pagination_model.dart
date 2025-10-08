import 'product_model.dart';

class ProductPagination {
  final List<Product> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final List<Sort> sorts;

  ProductPagination({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.sorts,
  });

  factory ProductPagination.fromMap(Map<String, dynamic> map) {
    return ProductPagination(
      content: List<Product>.from(
          (map['content'] ?? []).map((x) => Product.fromMap(x))),
      page: map['page'] ?? 0,
      size: map['size'] ?? 0,
      totalElements: map['total_elements'] ?? 0,
      totalPages: map['total_pages'] ?? 0,
      sorts: List<Sort>.from((map['sorts'] ?? []).map((x) => Sort.fromMap(x))),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content.map((x) => x.toMap()).toList(),
      'page': page,
      'size': size,
      'total_elements': totalElements,
      'total_pages': totalPages,
      'sorts': sorts.map((x) => x.toMap()).toList(),
    };
  }
}

class Sort {
  final String property;
  final String direction;

  Sort({
    required this.property,
    required this.direction,
  });

  factory Sort.fromMap(Map<String, dynamic> map) {
    return Sort(
      property: map['property'] ?? '',
      direction: map['direction'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'property': property,
      'direction': direction,
    };
  }
}

class ProductResponse {
  final String message;
  final int code;
  final ProductResponseData data;

  ProductResponse({
    required this.message,
    required this.code,
    required this.data,
  });

  factory ProductResponse.fromMap(Map<String, dynamic> map) {
    return ProductResponse(
      message: map['message'] ?? '',
      code: map['code'] ?? 0,
      data: ProductResponseData.fromMap(map['data'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'code': code,
      'data': data.toMap(),
    };
  }
}

class ProductResponseData {
  final ProductPagination result;

  ProductResponseData({
    required this.result,
  });

  factory ProductResponseData.fromMap(Map<String, dynamic> map) {
    return ProductResponseData(
      result: ProductPagination.fromMap(map['result'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'result': result.toMap(),
    };
  }
} 