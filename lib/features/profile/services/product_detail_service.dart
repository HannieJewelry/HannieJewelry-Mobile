import 'package:flutter/foundation.dart';
import '../models/product_detail_model.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../core/services/api_service.dart';

class ProductDetailService extends ChangeNotifier {
  final AuthService _authService;
  final ApiService _apiService;
  
  ProductDetail? _currentProduct;
  List<ProductDetail> _favoriteProducts = [];
  List<ProductDetail> _recentlyViewedProducts = [];
  bool _isLoading = false;
  String? _error;

  ProductDetailService(this._authService, this._apiService);

  // Getters
  ProductDetail? get currentProduct => _currentProduct;
  List<ProductDetail> get favoriteProducts => _favoriteProducts;
  List<ProductDetail> get recentlyViewedProducts => _recentlyViewedProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // GET Product Detail - /api/client/collections/{handle}
  Future<ProductDetail?> getProductDetail(String handle) async {
    if (handle.isEmpty) {
      _error = 'Product handle is required';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    if (kDebugMode) {
      print('🔍 ProductDetailService: Starting getProductDetail()');
      print('   Handle: $handle');
    }

    try {
      final response = await _apiService.get('/api/client/collections/$handle');
      
      if (kDebugMode) {
        print('📋 ProductDetailService: GET Product Detail Response:');
        print('   Full Response: $response');
        print('   Response Type: ${response.runtimeType}');
        print('   Has Code: ${response.containsKey('code')}');
        print('   Code Value: ${response['code']}');
        print('   Has Data: ${response.containsKey('data')}');
      }
      
      if (response['code'] == 200 && response['data'] != null) {
        _currentProduct = ProductDetail.fromMap(response['data']);
        _error = null;
        
        // Add to recently viewed products
        _addToRecentlyViewed(_currentProduct!);
        
        if (kDebugMode) {
          print('✅ ProductDetailService: Product loaded successfully');
          print('   Product: ${_currentProduct?.displayTitle}');
          print('   Available: ${_currentProduct?.available}');
          print('   Images: ${_currentProduct?.images.length}');
          print('   Variants: ${_currentProduct?.variants.length}');
        }
        notifyListeners();
        return _currentProduct;
      } else {
        _error = response['message'] ?? 'Failed to fetch product detail';
        print('❌ ProductDetailService: Error fetching product detail');
        print('   Error Code: ${response['code']}');
        print('   Error Message: ${response['message']}');
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error when getting product detail: $e';
      print('❌ ProductDetailService: Exception in getProductDetail()');
      print('   Exception: $e');
      print('   Exception Type: ${e.runtimeType}');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('🏁 ProductDetailService: getProductDetail() completed');
      }
    }
  }

  // Add product to favorites
  void addToFavorites(ProductDetail product) {
    if (!_favoriteProducts.any((p) => p.id == product.id)) {
      _favoriteProducts.add(product);
      notifyListeners();
      
      if (kDebugMode) {
        print('❤️ ProductDetailService: Added to favorites: ${product.displayTitle}');
      }
    }
  }

  // Remove product from favorites
  void removeFromFavorites(String productId) {
    _favoriteProducts.removeWhere((p) => p.id == productId);
    notifyListeners();
    
    if (kDebugMode) {
      print('💔 ProductDetailService: Removed from favorites: $productId');
    }
  }

  // Check if product is in favorites
  bool isFavorite(String productId) {
    return _favoriteProducts.any((p) => p.id == productId);
  }

  // Toggle favorite status
  void toggleFavorite(ProductDetail product) {
    if (isFavorite(product.id)) {
      removeFromFavorites(product.id);
    } else {
      addToFavorites(product);
    }
  }

  // Add to recently viewed products (private method)
  void _addToRecentlyViewed(ProductDetail product) {
    // Remove if already exists
    _recentlyViewedProducts.removeWhere((p) => p.id == product.id);
    
    // Add to beginning
    _recentlyViewedProducts.insert(0, product);
    
    // Keep only last 10 items
    if (_recentlyViewedProducts.length > 10) {
      _recentlyViewedProducts = _recentlyViewedProducts.take(10).toList();
    }
    
    if (kDebugMode) {
      print('👀 ProductDetailService: Added to recently viewed: ${product.displayTitle}');
      print('   Recently viewed count: ${_recentlyViewedProducts.length}');
    }
  }

  // Clear recently viewed products
  void clearRecentlyViewed() {
    _recentlyViewedProducts.clear();
    notifyListeners();
    
    if (kDebugMode) {
      print('🧹 ProductDetailService: Cleared recently viewed products');
    }
  }

  // Get product by ID from cache (favorites or recently viewed)
  ProductDetail? getProductFromCache(String productId) {
    // Check favorites first
    for (var product in _favoriteProducts) {
      if (product.id == productId) return product;
    }
    
    // Check recently viewed
    for (var product in _recentlyViewedProducts) {
      if (product.id == productId) return product;
    }
    
    return null;
  }

  // Search products in cache
  List<ProductDetail> searchInCache(String query) {
    final results = <ProductDetail>[];
    final lowerQuery = query.toLowerCase();
    
    // Search in favorites
    for (var product in _favoriteProducts) {
      if (product.displayTitle.toLowerCase().contains(lowerQuery) ||
          product.tags.toLowerCase().contains(lowerQuery) ||
          product.vendor.toLowerCase().contains(lowerQuery)) {
        results.add(product);
      }
    }
    
    // Search in recently viewed (avoid duplicates)
    for (var product in _recentlyViewedProducts) {
      if (!results.any((p) => p.id == product.id)) {
        if (product.displayTitle.toLowerCase().contains(lowerQuery) ||
            product.tags.toLowerCase().contains(lowerQuery) ||
            product.vendor.toLowerCase().contains(lowerQuery)) {
          results.add(product);
        }
      }
    }
    
    return results;
  }

  // Get available variants for current product
  List<ProductVariant> getAvailableVariants() {
    if (_currentProduct == null) return [];
    return _currentProduct!.variants.where((v) => v.available).toList();
  }

  // Get variant by options
  ProductVariant? getVariantByOptions(Map<String, String> selectedOptions) {
    if (_currentProduct == null) return null;
    
    for (var variant in _currentProduct!.variants) {
      bool matches = true;
      
      if (selectedOptions.containsKey('option1') && variant.option1 != selectedOptions['option1']) {
        matches = false;
      }
      if (selectedOptions.containsKey('option2') && variant.option2 != selectedOptions['option2']) {
        matches = false;
      }
      if (selectedOptions.containsKey('option3') && variant.option3 != selectedOptions['option3']) {
        matches = false;
      }
      
      if (matches) return variant;
    }
    
    return null;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear current product
  void clearCurrentProduct() {
    _currentProduct = null;
    _error = null;
    notifyListeners();
  }

  // Clear all data
  void clearAll() {
    _currentProduct = null;
    _favoriteProducts.clear();
    _recentlyViewedProducts.clear();
    _error = null;
    notifyListeners();
  }
}
