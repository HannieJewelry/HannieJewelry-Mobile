import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/shared_bottom_navigation.dart';
import '../../../routes/app_routes.dart';
import '../../cart/services/cart_service.dart';
import '../models/product_model.dart';
import '../models/product_category_model.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import 'product_search_screen.dart';
import '../widgets/product_card.dart';
import '../widgets/product_filter.dart';
import '../widgets/product_sort.dart';

class ProductBrowseScreen extends StatefulWidget {
  const ProductBrowseScreen({Key? key}) : super(key: key);

  @override
  State<ProductBrowseScreen> createState() => _ProductBrowseScreenState();
}

class _ProductBrowseScreenState extends State<ProductBrowseScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic> _activeFilters = {};

  @override
  void initState() {
    super.initState();

    // Initialize data loading
    Future.microtask(() {
      _loadData();
    });

    _scrollController.addListener(_onScroll);
    
    // Set context for CartService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartService = Provider.of<CartService>(context, listen: false);
      cartService.setContext(context);
      
      // Refresh cart data to ensure accurate information
      cartService.refreshCart();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final productService = Provider.of<ProductService>(context);
    if (productService.categories.isNotEmpty &&
        (_tabController == null || _tabController!.length != productService.categories.length)) {
      _tabController = TabController(
        length: productService.categories.length,
        vsync: this,
      );
      _tabController!.addListener(_handleTabChange);
    }
  }

  Future<void> _loadData() async {
    final productService = Provider.of<ProductService>(context, listen: false);

    try {
      // Hiển thị trạng thái loading
      setState(() {});

      // Tải danh sách danh mục và bộ lọc
      await Future.wait([
        productService.fetchFilterOptions(),
        productService.fetchCategories(),
      ]);

      if (mounted && productService.categories.isNotEmpty) {
        // Khởi tạo TabController sau khi có danh mục
        setState(() {
          _tabController = TabController(
            length: productService.categories.length,
            vsync: this,
          );

          _tabController!.addListener(_handleTabChange);
        });

        // Tải sản phẩm của danh mục đã chọn
        if (productService.selectedCategory != null) {
          // Đặt lại trạng thái phân trang
          productService.resetPagination();
          
          // Tải sản phẩm mới
          await productService.fetchProductsByCollection(
            productService.selectedCategory!.handle,
            refresh: true,
          );
        }
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      // Hiển thị lỗi nếu cần thiết
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _handleTabChange() {
    if (_tabController != null && _tabController!.indexIsChanging == false) {
      final productService = Provider.of<ProductService>(context, listen: false);
      final categories = productService.categories;

      if (categories.isNotEmpty && _tabController!.index < categories.length) {
        final selectedCategory = categories[_tabController!.index];
        productService.setSelectedCategory(selectedCategory);
        productService.resetPagination();
        productService.fetchProductsByCollection(selectedCategory.handle, refresh: true);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final productService = Provider.of<ProductService>(context, listen: false);
      if (!productService.isLoadingMore && productService.hasMoreProducts) {
        productService.loadMoreProducts();
      }
    }
  }

  Future<void> _refreshProducts() async {
    final productService = Provider.of<ProductService>(context, listen: false);
    if (productService.selectedCategory != null) {
      await productService.fetchProductsByCollection(
        productService.selectedCategory!.handle,
        refresh: true,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);

    if (productService.categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Select Products'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: productService.categories.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFE57373),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Select Product',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                // Clear all filters and search data before navigating to search screen
                context.read<ProductService>().clearSearch();
                context.read<ProductService>().clearFilters();
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductSearchScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(88),
            child: Column(
              children: [
                // Category tabs
                Container(
                  height: 44,
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide.none,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                    indicator: const BoxDecoration(),
                    dividerColor: Colors.transparent,
                    tabs: productService.categories.map((category) {
                      return Tab(text: category.title);
                    }).toList(),
                  ),
                ),
                // Filter and Sort row
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
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: productService.categories.map((category) {
            return _buildCategoryContent(category);
          }).toList(),
        ),
        bottomNavigationBar: const SharedBottomNavigation(currentIndex: 1),
      ),
    );
  }


  Widget _buildCartSummary() {
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        if (cartService.itemCount == 0) {
          return const SizedBox.shrink(); // Ẩn thanh khi giỏ hàng trống
        }
        
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, Routes.CART),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.red.shade300,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Hiển thị số lượng sản phẩm
                Container(
                  margin: const EdgeInsets.only(left: 16),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${cartService.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                
                // Hiển thị tổng giá tiền
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${_formatPrice(cartService.totalPrice)}đ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                
                // Nút xem giỏ hàng
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: double.infinity,
                  child: Center(
                    child: Text(
                      'Xem giỏ hàng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget _buildCategoryContent(ProductCategory category) {
    return Consumer<ProductService>(
      builder: (context, productService, child) {
        if (productService.isLoading && productService.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (productService.error.isNotEmpty && productService.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(productService.error),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshProducts,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        return _buildProductGrid(productService);
      },
    );
  }

  Widget _buildFiltersRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _showFilterDrawer,
            icon: const Icon(Icons.filter_list),
            label: Text(_activeFilters.isEmpty ? 'Filter' : 'Filter (${_activeFilters.length})'),
          ),
          OutlinedButton.icon(
            onPressed: _showSortDrawer,
            icon: const Icon(Icons.sort),
            label: const Text('Sort'),
          ),
        ],
      ),
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
          onClose: () => Navigator.of(context).pop(),
          onApplySort: (sortProperty, direction) {
            final productService = Provider.of<ProductService>(context, listen: false);
            productService.setSorting(sortProperty, direction);
            
            if (productService.selectedCategory != null) {
              productService.fetchProductsByCollection(
                productService.selectedCategory!.handle,
                refresh: true,
              );
            }
            
            Navigator.of(context).pop();
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
      routeSettings: RouteSettings(name: Routes.PRODUCT_BROWSE),
    );
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

            final productService = Provider.of<ProductService>(context, listen: false);
            productService.fetchProductsWithFilters(_activeFilters, refresh: true);
          },
          onCategorySelected: (category) {
            final productService = Provider.of<ProductService>(context, listen: false);
            final categories = productService.categories;

            int categoryIndex = categories.indexOf(category);
            if (categoryIndex != -1 && _tabController != null) {
              _tabController!.animateTo(categoryIndex);
            }

            productService.setSelectedCategory(category);
            productService.resetPagination();
            productService.fetchProductsByCollection(category.handle, refresh: true);
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
      routeSettings: RouteSettings(name: Routes.PRODUCT_BROWSE),
    );
  }

  Widget _buildProductGrid(ProductService productService) {
    final List<Product> filteredProducts = _activeFilters.isNotEmpty
        ? productService.applyFilters(productService.products, _activeFilters)
        : productService.products;

    if (filteredProducts.isEmpty && _activeFilters.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No products match the selected filters'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _activeFilters.clear();
                });
                productService.fetchProductsWithFilters({}, refresh: true);
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: productService.isLoadingMore && _activeFilters.isEmpty
          ? filteredProducts.length + 2
          : filteredProducts.length,
      itemBuilder: (context, index) {
        if (index >= filteredProducts.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final product = filteredProducts[index];
        return ProductCard(
          product: product,
          onTap: () => _navigateToProductDetail(product),
          onAddToCart: () {}, // Handling is now done in the ProductCard
        );
      },
    );
  }

  void _navigateToProductDetail(Product product) {
    Navigator.pushNamed(
      context,
      '/product-detail',
      arguments: {'productHandle': product.handle},
    );
  }

  void _addToCart(Product product) {
    final cartService = Provider.of<CartService>(context, listen: false);
    
    // Get product info to add to cart
    final String productName = product.title;
    final double productPrice = product.price;
    
    // Get product image URL
    final String imageUrl = product.image?.src ?? 
                           (product.images.isNotEmpty ? product.images.first.src : 'assets/images/placeholder.png');
    
    // Use variant ID if available, otherwise use product ID
    final variantId = product.variants.isNotEmpty ? product.variants.first.id : product.id;
    
    // Add product to cart
    cartService.addItem(
      variantId, 
      productName, 
      productPrice, 
      imageUrl,
      quantity: 1
    ).then((_) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} added to cart'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () => Navigator.pushNamed(context, Routes.CART),
          ),
        ),
      );
    }).catchError((error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add ${product.title} to cart: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}