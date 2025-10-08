import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../app/app_config.dart';
import '../../../core/services/api_service.dart';
import '../models/product_model.dart';
import '../models/product_category_model.dart';
import '../models/product_pagination_model.dart';
import '../models/product_type_model.dart';

class ProductService extends ChangeNotifier {
  final ApiService _apiService;
  
  List<Product> _products = [];
  ProductPagination? _productPagination;
  List<ProductCategory> _categories = [];
  ProductCategory? _selectedCategory;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingCategories = false;
  bool _isLoadingFilters = false;
  bool _isLoadingProductTypes = false;
  bool _isLoadingVendors = false;
  String _error = '';
  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic> _filters = {};
  String _sortProperty = '';
  String _sortDirection = '';
  bool _initialized = false;
  
  // Danh sách lọc động từ API
  List<Map<String, String>> _productTypes = [];
  List<Map<String, String>> _vendors = [];
  
  // Search related properties
  List<Product> _searchResults = [];
  List<ProductType> _productTypeSuggestions = [];
  bool _isSearching = false;
  String _searchQuery = '';

  ProductService(this._apiService) {
    // Tự động khởi tạo dữ liệu khi service được tạo
    _initializeData();
  }

  // Phương thức khởi tạo dữ liệu
  Future<void> _initializeData() async {
    if (_initialized) return;
    
    try {
      await fetchCategories();
      if (_categories.isNotEmpty && _selectedCategory != null) {
        await fetchProductsByCollection(_selectedCategory!.handle, refresh: true);
      }
      _initialized = true;
    } catch (e) {
      print('❌ Error initializing ProductService: $e');
    }
  }

  // Getters
  List<Product> get products => _products;
  ProductPagination? get productPagination => _productPagination;
  List<ProductCategory> get categories => _categories;
  ProductCategory? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingFilters => _isLoadingFilters;
  bool get isLoadingProductTypes => _isLoadingProductTypes;
  bool get isLoadingVendors => _isLoadingVendors;
  String get error => _error;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  Map<String, dynamic> get filters => _filters;
  List<Map<String, String>> get productTypes => _productTypes;
  List<Map<String, String>> get vendors => _vendors;
  String get sortProperty => _sortProperty;
  String get sortDirection => _sortDirection;
  bool get hasMoreProducts => _productPagination != null && 
    _currentPage < _productPagination!.totalPages;
  
  // Search getters
  List<Product> get searchResults => _searchResults;
  List<ProductType> get productTypeSuggestions => _productTypeSuggestions;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
    
  // Set selected category
  void setSelectedCategory(ProductCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  // Set filters
  void setFilters(Map<String, dynamic> filters) {
    _filters = Map<String, dynamic>.from(filters);
    notifyListeners();
  }
  
  // Apply filters to search results
  void applyFiltersToSearch(Map<String, dynamic> filters) {
    _filters = Map<String, dynamic>.from(filters);
    if (_searchQuery.isNotEmpty) {
      searchProducts(_searchQuery);
    }
  }
  
  // Set sorting
  void setSorting(String property, String direction) {
    _sortProperty = property;
    _sortDirection = direction;
    notifyListeners();
  }
  
  // Clear filters
  void clearFilters() {
    _filters.clear();
    notifyListeners();
  }
  
  // Clear sorting
  void clearSorting() {
    _sortProperty = '';
    _sortDirection = '';
    notifyListeners();
  }
  
  // Fetch all filter options asynchronously
  Future<void> fetchFilterOptions() async {
    _isLoadingFilters = true;
    notifyListeners();
    
    try {
      // Run fetches in parallel
      await Future.wait([
        fetchProductTypes(),
        fetchVendors(),
      ]);
      
      _isLoadingFilters = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error fetching filter options: $e';
      _isLoadingFilters = false;
      notifyListeners();
    }
  }
  
  // Fetch product types
  Future<void> fetchProductTypes() async {
    _isLoadingProductTypes = true;
    notifyListeners();
    
    try {
      final productTypesResponse = await _apiService.get('/api/client/collections/product-types');
      
      if (productTypesResponse['code'] == 200 && productTypesResponse['data'] != null) {
        _productTypes = List<Map<String, String>>.from(
          productTypesResponse['data'].map((item) => {
            'id': item['id'].toString(),
            'name': item['name'].toString(),
          })
        );
      }
      
      _isLoadingProductTypes = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error fetching product types: $e';
      _isLoadingProductTypes = false;
      notifyListeners();
    }
  }
  
  // Fetch vendors
  Future<void> fetchVendors() async {
    _isLoadingVendors = true;
    notifyListeners();
    
    try {
      final vendorsResponse = await _apiService.get('/api/client/collections/vendors');
      
      if (vendorsResponse['code'] == 200 && vendorsResponse['data'] != null) {
        _vendors = List<Map<String, String>>.from(
          vendorsResponse['data'].map((item) => {
            'id': item['id'].toString(),
            'name': item['name'].toString(),
          })
        );
      }
      
      _isLoadingVendors = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error fetching vendors: $e';
      _isLoadingVendors = false;
      notifyListeners();
    }
  }
  
  // Fetch products with filters
  Future<void> fetchProductsWithFilters(Map<String, dynamic> filters, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _isLoading = true;
    } else if (_isLoadingMore) {
      return;
    } else if (!hasMoreProducts) {
      return;
    } else {
      _isLoadingMore = true;
    }
    
    _error = '';
    notifyListeners();
    
    try {
      // Build filter string for RSQL
      String filterString = '';
      
      if (filters.containsKey('vendor') && filters['vendor'] != null) {
        filterString += "vendor=='${filters['vendor']}';";
      }
      
      if (filters.containsKey('productType') && filters['productType'] != null) {
        filterString += "productType=='${filters['productType']}';";
      }
      
      if (filters.containsKey('minPrice') && filters['minPrice'] != null) {
        filterString += "variants.price>=${filters['minPrice']};";
      }
      
      if (filters.containsKey('maxPrice') && filters['maxPrice'] != null) {
        filterString += "variants.price<=${filters['maxPrice']};";
      }
      
      // Remove trailing semicolon if exists
      if (filterString.isNotEmpty && filterString.endsWith(';')) {
        filterString = filterString.substring(0, filterString.length - 1);
      }
      
      // Determine collection handle (all or specific collection)
      final collectionHandle = _selectedCategory != null 
          ? _selectedCategory!.handle 
          : 'all';
      
      // Build URL with query parameters
      String endpoint = '/api/client/collections/$collectionHandle/products?page=$_currentPage&size=$_pageSize';
      if (filterString.isNotEmpty) {
        endpoint += '&filter=$filterString';
      }
      
      // Add sorting if specified
      if (_sortProperty.isNotEmpty) {
        endpoint += '&sortProperty=$_sortProperty';
        if (_sortDirection.isNotEmpty) {
          endpoint += '&direction=$_sortDirection';
        }
      }
      
      final response = await _apiService.get(endpoint);
      
      if (response['code'] == 200 && response['data'] != null) {
        final productData = response['data']['result'];
        final List<dynamic> productsJson = productData['content'] ?? [];
        final List<Product> fetchedProducts = productsJson.map((json) => Product.fromMap(json)).toList();
        
        final pagination = ProductPagination(
          content: fetchedProducts,
          page: productData['page'] ?? 1,
          size: productData['size'] ?? 10,
          totalElements: productData['total_elements'] ?? 0,
          totalPages: productData['total_pages'] ?? 0,
          sorts: List<Sort>.from((productData['sorts'] ?? []).map((sort) => Sort.fromMap(sort))),
        );
        
        if (refresh) {
          _products = fetchedProducts;
          _productPagination = pagination;
        } else {
          _products.addAll(fetchedProducts);
          _productPagination = pagination;
          _currentPage++;
        }
        
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      } else {
        _error = 'Failed to load products: ${response['message'] ?? 'Unknown error'}';
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error fetching products: $e';
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  
  // Apply filters to products list
  List<Product> applyFilters(List<Product> products, Map<String, dynamic> filters) {
    if (filters.isEmpty) {
      return products;
    }
    
    return products.where((product) {
      // Filter by price range
      if (filters.containsKey('minPrice')) {
        final minPrice = filters['minPrice'] as int;
        if (product.price < minPrice) {
          return false;
        }
      }
      
      if (filters.containsKey('maxPrice')) {
        final maxPrice = filters['maxPrice'] as int;
        if (product.price > maxPrice) {
          return false;
        }
      }
      
      // Filter by brand/vendor
      if (filters.containsKey('vendor') && filters['vendor'] != null) {
        final vendor = filters['vendor'] as String;
        if (!product.vendor.contains(vendor)) {
          return false;
        }
      }
      
      // Filter by product type
      if (filters.containsKey('productType') && filters['productType'] != null) {
        final productType = filters['productType'] as String;
        if (!product.productType.contains(productType)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  // Fetch all collections (categories)
  Future<List<ProductCategory>> fetchCategories() async {
    _isLoadingCategories = true;
    _error = '';
    notifyListeners();
    
    try {
      final response = await _apiService.get('/api/client/collections');
      
      if (response['code'] == 200 && response['data'] != null) {
        final List<dynamic> categoriesJson = response['data'];
        final fetchedCategories = categoriesJson.map((json) => ProductCategory.fromMap(json)).toList();
        
        _categories = fetchedCategories;
        if (_categories.isNotEmpty && _selectedCategory == null) {
          _selectedCategory = _categories.first;
        }
        _isLoadingCategories = false;
        notifyListeners();
        return fetchedCategories;
      } else {
        _error = 'Failed to load categories: ${response['message'] ?? 'Unknown error'}';
        _isLoadingCategories = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      _error = 'Error fetching categories: $e';
      _isLoadingCategories = false;
      notifyListeners();
      return [];
    }
  }

  // Fetch products by collection handle with pagination
  Future<void> fetchProductsByCollection(String collectionHandle, {bool refresh = false}) async {
    // Nếu đang tải thêm sản phẩm và không phải refresh, thì không làm gì cả
    if (!refresh && _isLoadingMore) return;
    
    // Nếu không còn sản phẩm để tải và không phải refresh, thì không làm gì cả
    if (!refresh && _productPagination != null && !hasMoreProducts) return;
    
    // Cập nhật trạng thái tải
    if (refresh) {
      _currentPage = 1;
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    
    _error = '';
    notifyListeners();

    try {
      print('🔍 Fetching products for collection: $collectionHandle (page: $_currentPage)');
      
      // Build URL with query parameters
      String endpoint = '/api/client/collections/$collectionHandle/products?page=$_currentPage&size=$_pageSize';
      
      // Add sorting if specified
      if (_sortProperty.isNotEmpty) {
        endpoint += '&sortProperty=$_sortProperty';
        if (_sortDirection.isNotEmpty) {
          endpoint += '&direction=$_sortDirection';
        }
      }
      
      print('📡 API endpoint: $endpoint');
      
      // Use the correct API endpoint format
      final response = await _apiService.get(endpoint);
      
      print('📦 API response received: ${response['code']}');
      
      if (response['code'] == 200 && response['data'] != null) {
        final productData = response['data']['result'];
        final List<dynamic> productsJson = productData['content'] ?? [];
        
        print('📋 Found ${productsJson.length} products');
        
        final List<Product> fetchedProducts = productsJson.map((json) => Product.fromMap(json)).toList();
        
        final pagination = ProductPagination(
          content: fetchedProducts,
          page: productData['page'] ?? 1,
          size: productData['size'] ?? 10,
          totalElements: productData['total_elements'] ?? 0,
          totalPages: productData['total_pages'] ?? 0,
          sorts: List<Sort>.from((productData['sorts'] ?? []).map((sort) => Sort.fromMap(sort))),
        );
        
        if (refresh) {
          _products = fetchedProducts;
          _productPagination = pagination;
          print('🔄 Products refreshed: ${_products.length} items');
        } else {
          _products.addAll(fetchedProducts);
          _productPagination = pagination;
          _currentPage++;
          print('📥 Products added: ${fetchedProducts.length} items (total: ${_products.length})');
        }
        
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      } else {
        _error = 'Failed to load products: ${response['message'] ?? 'Unknown error'}';
        print('❌ Error: $_error');
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error fetching products: $e';
      print('❌ Exception: $_error');
      _isLoading = false;
    }
  }

  // Fetch product details by product handle
  Future<Product?> fetchProductByHandle(String productHandle) async {
    // Set loading state outside of the build phase
    Future.microtask(() {
      _isLoading = true;
      _error = '';
      notifyListeners();
    });
    
    try {
      // Use the correct API endpoint for product details
      final response = await _apiService.get('/api/client/collections/$productHandle');
      
      if (response['code'] == 200 && response['data'] != null) {
        final productJson = response['data'];
        final product = Product.fromMap(productJson);
        return product;
      } else {
        _error = 'Failed to load product: ${response['message'] ?? 'Unknown error'}';
        return null;
      }
    } catch (e) {
      _error = 'Error fetching product: $e';
      return null;
    } finally {
      // Update loading state outside of the build phase
      Future.microtask(() {
        _isLoading = false;
        notifyListeners();
      });
    }
  }
  
  // Fetch product by ID
  Future<Product?> fetchProductById(String id) async {
    // Set loading state outside of the build phase
    Future.microtask(() {
      _isLoading = true;
      _error = '';
      notifyListeners();
    });
    
    try {
      // Use the correct API endpoint for product details by ID
      final response = await _apiService.get('/api/client/products/$id');
      
      if (response['code'] == 200 && response['data'] != null) {
        final productJson = response['data'];
        final product = Product.fromMap(productJson);
        return product;
      } else {
        _error = 'Failed to load product: ${response['message'] ?? 'Unknown error'}';
        return null;
      }
    } catch (e) {
      _error = 'Error fetching product: $e';
      return null;
    } finally {
      // Update loading state outside of the build phase
      Future.microtask(() {
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  // Load more products for the current collection
  Future<void> loadMoreProducts() async {
    if (!hasMoreProducts || _isLoadingMore || _selectedCategory == null) {
      return;
    }
    
    await fetchProductsByCollection(_selectedCategory!.handle);
  }

  // Fetch products by collection handle for background preloading (doesn't update UI state)
  Future<List<Product>> fetchProductsByCollectionBackground(String collectionHandle) async {
    try {
      print('🔍 Background fetching products for collection: $collectionHandle');
      
      // Build URL with query parameters
      String endpoint = '/api/client/collections/$collectionHandle/products?page=1&size=$_pageSize';
      
      // Add sorting if specified
      if (_sortProperty.isNotEmpty) {
        endpoint += '&sortProperty=$_sortProperty';
        if (_sortDirection.isNotEmpty) {
          endpoint += '&direction=$_sortDirection';
        }
      }
      
      print('📡 Background API endpoint: $endpoint');
      
      // Use the correct API endpoint format
      final response = await _apiService.get(endpoint);
      
      print('📦 Background API response received: ${response['code']}');
      
      if (response['code'] == 200 && response['data'] != null) {
        final productData = response['data']['result'];
        final List<dynamic> productsJson = productData['content'] ?? [];
        
        print('📋 Background found ${productsJson.length} products');
        
        final List<Product> fetchedProducts = productsJson.map((json) => Product.fromMap(json)).toList();
        
        return fetchedProducts;
      } else {
        print('❌ Background error: ${response['message'] ?? 'Unknown error'}');
        return [];
      }
    } catch (e) {
      print('❌ Background exception: $e');
      return [];
    }
  }

  // Reset pagination
  void resetPagination() {
    _currentPage = 1;
    _products = [];
    _productPagination = null;
    notifyListeners();
  }

  // Search products by title with filters and sorting
  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    _error = '';
    notifyListeners();

    try {
      // Build search endpoint with filters and sorting
      String filterString = 'title=ilike="${Uri.encodeComponent(query)}"';
      
      // Add additional filters if they exist
      if (_filters.containsKey('vendor') && _filters['vendor'] != null) {
        filterString += ';vendor=="${_filters['vendor']}"';
      }
      
      if (_filters.containsKey('productType') && _filters['productType'] != null) {
        filterString += ';productType=="${_filters['productType']}"';
      }
      
      if (_filters.containsKey('minPrice') && _filters['minPrice'] != null) {
        filterString += ';variants.price>=${_filters['minPrice']}';
      }
      
      if (_filters.containsKey('maxPrice') && _filters['maxPrice'] != null) {
        filterString += ';variants.price<=${_filters['maxPrice']}';
      }
      
      // Build URL with query parameters
      String endpoint = '/api/client/collections/all/products?filter=$filterString';
      
      // Add sorting if specified
      if (_sortProperty.isNotEmpty) {
        endpoint += '&sortProperty=$_sortProperty';
        if (_sortDirection.isNotEmpty) {
          endpoint += '&direction=$_sortDirection';
        }
      }
      
      final response = await _apiService.get(endpoint);
      
      if (response['code'] == 200 && response['data'] != null) {
        final productData = response['data']['result'];
        final List<dynamic> productsJson = productData['content'] ?? [];
        _searchResults = productsJson.map((json) => Product.fromMap(json)).toList();
        
        print('🔍 Search results: ${_searchResults.length} products found for "$query"');
      } else {
        _error = 'Failed to search products: ${response['message'] ?? 'Unknown error'}';
        _searchResults = [];
      }
    } catch (e) {
      _error = 'Error searching products: $e';
      _searchResults = [];
      print('❌ Search error: $_error');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Fetch product type suggestions
  Future<void> fetchProductTypeSuggestions() async {
    _isLoadingProductTypes = true;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/api/client/collections/product-types');
      
      if (response['code'] == 200 && response['data'] != null) {
        final List<dynamic> productTypesJson = response['data'];
        _productTypeSuggestions = productTypesJson.map((json) => ProductType.fromMap(json)).toList();
        
        print('💡 Product type suggestions: ${_productTypeSuggestions.length} types loaded');
      } else {
        _error = 'Failed to load product types: ${response['message'] ?? 'Unknown error'}';
        _productTypeSuggestions = [];
      }
    } catch (e) {
      _error = 'Error fetching product types: $e';
      _productTypeSuggestions = [];
      print('❌ Product types error: $_error');
    } finally {
      _isLoadingProductTypes = false;
      notifyListeners();
    }
  }

  // Clear search results
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    _isSearching = false;
    notifyListeners();
  }

  // Set search query without triggering search
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}