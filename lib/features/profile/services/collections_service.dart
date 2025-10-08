import 'package:flutter/foundation.dart';
import '../models/product_detail_model.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../core/services/api_service.dart';

class CollectionsResult {
  final List<ProductDetail> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final List<Map<String, String>> sorts;

  CollectionsResult({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.sorts,
  });

  factory CollectionsResult.fromMap(Map<String, dynamic> map) {
    return CollectionsResult(
      content: (map['content'] as List<dynamic>?)
          ?.map((item) => ProductDetail.fromMap(item))
          .toList() ?? [],
      page: map['page'] ?? 1,
      size: map['size'] ?? 10,
      totalElements: map['total_elements'] ?? 0,
      totalPages: map['total_pages'] ?? 1,
      sorts: (map['sorts'] as List<dynamic>?)
          ?.map((item) => Map<String, String>.from(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content.map((product) => product.toMap()).toList(),
      'page': page,
      'size': size,
      'total_elements': totalElements,
      'total_pages': totalPages,
      'sorts': sorts,
    };
  }
}

class CollectionsService extends ChangeNotifier {
  final AuthService _authService;
  final ApiService _apiService;
  
  CollectionsResult? _currentResult;
  List<ProductDetail> _allProducts = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _pageSize = 10;

  CollectionsService(this._authService, this._apiService);

  // Getters
  CollectionsResult? get currentResult => _currentResult;
  List<ProductDetail> get allProducts => _allProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  bool get hasMorePages => _currentResult != null && _currentPage < _currentResult!.totalPages;

  // GET Collection Products - /api/client/collections/{handle}/products
  Future<CollectionsResult?> getCollectionProducts(
    String collectionHandle, {
    int page = 1,
    int size = 10,
    bool append = false,
  }) async {
    if (collectionHandle.isEmpty) {
      _error = 'Collection handle is required';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    _currentPage = page;
    _pageSize = size;
    notifyListeners();

    if (kDebugMode) {
      print('🔍 CollectionsService: Starting getCollectionProducts()');
      print('   Collection Handle: $collectionHandle');
      print('   Page: $page, Size: $size');
      print('   Append: $append');
    }

    try {
      final response = await _apiService.get(
        '/api/client/collections/$collectionHandle/products?page=$page&size=$size'
      );
      
      if (kDebugMode) {
        print('📋 CollectionsService: GET Collection Products Response:');
        print('   Full Response: $response');
        print('   Response Type: ${response.runtimeType}');
        print('   Has Code: ${response.containsKey('code')}');
        print('   Code Value: ${response['code']}');
        print('   Has Data: ${response.containsKey('data')}');
      }
      
      if (response['code'] == 200 && response['data'] != null) {
        final resultData = response['data']['result'];
        if (resultData != null) {
          _currentResult = CollectionsResult.fromMap(resultData);
          
          if (append && _allProducts.isNotEmpty) {
            // Append new products to existing list
            _allProducts.addAll(_currentResult!.content);
          } else {
            // Replace with new products
            _allProducts = List.from(_currentResult!.content);
          }
          
          _error = null;
          
          if (kDebugMode) {
            print('✅ CollectionsService: Collection products loaded successfully');
            print('   Products count: ${_currentResult!.content.length}');
            print('   Total elements: ${_currentResult!.totalElements}');
            print('   Current page: ${_currentResult!.page}');
            print('   Total pages: ${_currentResult!.totalPages}');
            print('   All products count: ${_allProducts.length}');
          }
          
          notifyListeners();
          return _currentResult;
        } else {
          _error = 'Invalid response format: missing result data';
          print('❌ CollectionsService: Invalid response format');
          notifyListeners();
          return null;
        }
      } else {
        _error = response['message'] ?? 'Failed to fetch collection products';
        print('❌ CollectionsService: Error fetching collection products');
        print('   Error Code: ${response['code']}');
        print('   Error Message: ${response['message']}');
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error when getting collection products: $e';
      print('❌ CollectionsService: Exception in getCollectionProducts()');
      print('   Exception: $e');
      print('   Exception Type: ${e.runtimeType}');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('🏁 CollectionsService: getCollectionProducts() completed');
      }
    }
  }

  // Load next page of products
  Future<CollectionsResult?> loadNextPage(String collectionHandle) async {
    if (!hasMorePages || _isLoading) return _currentResult;
    
    return await getCollectionProducts(
      collectionHandle,
      page: _currentPage + 1,
      size: _pageSize,
      append: true,
    );
  }

  // Refresh products (reload first page)
  Future<CollectionsResult?> refreshProducts(String collectionHandle) async {
    return await getCollectionProducts(
      collectionHandle,
      page: 1,
      size: _pageSize,
      append: false,
    );
  }

  // Search products in current collection
  List<ProductDetail> searchProducts(String query) {
    if (query.isEmpty) return _allProducts;
    
    final lowerQuery = query.toLowerCase();
    return _allProducts.where((product) {
      return product.displayTitle.toLowerCase().contains(lowerQuery) ||
             product.tags.toLowerCase().contains(lowerQuery) ||
             product.vendor.toLowerCase().contains(lowerQuery) ||
             product.productType.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Filter products by availability
  List<ProductDetail> getAvailableProducts() {
    return _allProducts.where((product) => product.available).toList();
  }

  // Filter products by vendor
  List<ProductDetail> getProductsByVendor(String vendor) {
    return _allProducts.where((product) => 
        product.vendor.toLowerCase() == vendor.toLowerCase()).toList();
  }

  // Filter products by product type
  List<ProductDetail> getProductsByType(String productType) {
    return _allProducts.where((product) => 
        product.productType.toLowerCase() == productType.toLowerCase()).toList();
  }

  // Get unique vendors from current products
  List<String> getUniqueVendors() {
    final vendors = _allProducts
        .map((product) => product.vendor)
        .where((vendor) => vendor.isNotEmpty)
        .toSet()
        .toList();
    vendors.sort();
    return vendors;
  }

  // Get unique product types from current products
  List<String> getUniqueProductTypes() {
    final types = _allProducts
        .map((product) => product.productType)
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();
    types.sort();
    return types;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data
  void clearAll() {
    _currentResult = null;
    _allProducts.clear();
    _error = null;
    _currentPage = 1;
    notifyListeners();
  }
}
