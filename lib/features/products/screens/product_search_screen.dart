import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/product_service.dart';
import '../models/product_type_model.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import '../widgets/product_filter.dart';
import '../widgets/product_sort.dart';
import 'product_detail_screen.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({Key? key}) : super(key: key);

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _recentSearches = [];
  Map<String, dynamic> _activeFilters = {};
  bool _hasInteractedWithInput = false; // Track if user tapped search input
  static const String _recentSearchesKey = 'recent_searches';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    // Load product type suggestions when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductService>().fetchProductTypeSuggestions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    
    // Reset all search data when exiting to browse screen
    context.read<ProductService>().clearSearch();
    context.read<ProductService>().clearFilters();
    _activeFilters.clear();
    super.dispose();
  }

  // Load recent searches from SharedPreferences
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_recentSearchesKey) ?? [];
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  // Save recent searches to SharedPreferences
  Future<void> _saveRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _recentSearches);
    } catch (e) {
      print('Error saving recent searches: $e');
    }
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      // Close keyboard when performing search
      _searchFocusNode.unfocus();
      
      context.read<ProductService>().searchProducts(query);
      
      // Add to recent searches and save to local storage
      setState(() {
        _recentSearches.remove(query);
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      });
      _saveRecentSearches();
    }
  }

  void _performSearchWithFilters() {
    final productService = context.read<ProductService>();
    if (productService.searchQuery.isNotEmpty) {
      // Re-perform search with current filters and sorting
      productService.searchProducts(productService.searchQuery);
    }
  }

  void _showFilterDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: ProductFilterDrawer(
          initialFilters: _activeFilters,
          onApplyFilters: (filters) {
            setState(() {
              _activeFilters = filters;
            });
            Navigator.pop(context);
            // Apply filters to ProductService and re-search
            context.read<ProductService>().applyFiltersToSearch(filters);
          },
          onCategorySelected: null, // Disable category navigation in search screen
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final begin = Offset(1.0, 0.0);
        final end = Offset.zero;
        final curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  void _showSortDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: ProductSortDrawer(
          onClose: () => Navigator.pop(context),
          onApplySort: (sortBy, sortOrder) {
            Navigator.pop(context);
            // Apply sorting to ProductService and re-search
            context.read<ProductService>().setSorting(sortBy, sortOrder);
            if (context.read<ProductService>().searchQuery.isNotEmpty) {
              context.read<ProductService>().searchProducts(context.read<ProductService>().searchQuery);
            }
          },
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final begin = Offset(1.0, 0.0);
        final end = Offset.zero;
        final curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ProductService>().clearSearch();
    setState(() {});
  }

  void _removeRecentSearch(String search) {
    setState(() {
      _recentSearches.remove(search);
    });
    _saveRecentSearches();
  }

  void _clearAllRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
    _saveRecentSearches();
  }

  // Handle back button behavior based on interaction state
  Future<bool> _handleBackButton() async {
    final productService = context.read<ProductService>();
    
    // If user tapped search input and there are search results, preserve state
    if (_hasInteractedWithInput && productService.searchQuery.isNotEmpty) {
      productService.clearSearch();
      setState(() {});
      return false; // Don't exit, stay in search screen
    }
    
    // If no interaction with input or no search results, exit and reset
    return true; // Allow exit (dispose will handle cleanup)
  }

  // Handle AppBar back button press
  void _handleBackButtonPressed() {
    final productService = context.read<ProductService>();
    
    // If user tapped search input and there are search results, preserve state
    if (_hasInteractedWithInput && productService.searchQuery.isNotEmpty) {
      productService.clearSearch();
      setState(() {});
    } else {
      // If no interaction with input or no search results, exit and reset
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return _handleBackButton();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFE57373), // Pink color from image
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              _handleBackButtonPressed();
            },
          ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: _performSearch,
            onTap: () {
              // Mark that user has interacted with input
              _hasInteractedWithInput = true;
              // Reset search when tapping input field to show suggestions
              if (context.read<ProductService>().searchQuery.isNotEmpty) {
                context.read<ProductService>().clearSearch();
                setState(() {});
              }
            },
          ),
        ),
      ),
      body: Consumer<ProductService>(
        builder: (context, productService, child) {
          // Show search results if there's a query
          if (productService.searchQuery.isNotEmpty) {
            return _buildSearchResults(productService);
          }
          
          // Show search suggestions and recent searches
          return _buildSearchSuggestions(productService);
        },
      ),
      ),
    );
  }

  Widget _buildSearchResults(ProductService productService) {
    if (productService.isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE57373)),
        ),
      );
    }

    if (productService.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy sản phẩm nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filter and Sort bar
        Container(
          height: 44,
          color: Colors.grey.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Filter button - left aligned
              TextButton.icon(
                onPressed: _showFilterDrawer,
                icon: const Icon(Icons.filter_list, size: 16, color: Colors.black87),
                label: Text(
                  _activeFilters.isEmpty ? 'Filter' : 'Filter (${_activeFilters.length})',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
              ),
              const Spacer(),
              // Sort button - right aligned
              TextButton.icon(
                onPressed: _showSortDrawer,
                icon: const Icon(Icons.sort, size: 16, color: Colors.black87),
                label: const Text(
                  'Sort',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ),
        // Search results grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: productService.searchResults.length,
            itemBuilder: (context, index) {
              final product = productService.searchResults[index];
              return ProductCard(
                product: product,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productHandle: product.handle,
                      ),
                    ),
                  );
                },
                onAddToCart: () {
                  // Handle add to cart functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã thêm vào giỏ hàng'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSuggestions(ProductService productService) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches section
          if (_recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tìm kiếm gần đây',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearAllRecentSearches,
                    child: const Text(
                      'Xóa hết',
                      style: TextStyle(
                        color: Color(0xFFE57373),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ..._recentSearches.map((search) => ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(search),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => _removeRecentSearch(search),
              ),
              onTap: () {
                _searchController.text = search;
                _performSearch(search);
              },
            )),
            const Divider(),
          ],
          
          // Product type suggestions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Suggestions for you',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          
          if (productService.isLoadingProductTypes)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE57373)),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: productService.productTypeSuggestions.length,
              itemBuilder: (context, index) {
                final productType = productService.productTypeSuggestions[index];
                return _buildSuggestionCard(productType);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(ProductType productType) {
    return GestureDetector(
      onTap: () {
        _searchController.text = productType.name;
        _performSearch(productType.name);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon/Image placeholder
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE57373).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: productType.image != null && productType.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        productType.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.category,
                            color: const Color(0xFFE57373),
                            size: 20,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.category,
                      color: const Color(0xFFE57373),
                      size: 20,
                    ),
            ),
            // Product type name
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  productType.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
