import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/auth_guard_service.dart';
import '../../../core/widgets/shared_bottom_navigation.dart';
import '../../../routes/app_routes.dart';

import '../../auth/services/auth_service.dart';
import '../../cart/services/cart_service.dart';
import '../../products/models/product_category_model.dart';
import '../../products/models/product_model.dart';
import '../../products/services/product_service.dart';

// Import the new widget components
import '../widgets/promotional_carousel.dart';
import '../widgets/quick_actions.dart';
import '../widgets/flash_sale_section.dart';
import '../widgets/trending_section.dart';
import '../widgets/category_products_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  
  // Cache for products by category to avoid reloading
  Map<String, List<Product>> _categoryProductsCache = {};
  String? _currentCategoryHandle;
  bool _isPreloadingCategories = false;
  Set<String> _preloadedCategories = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    print('🏠 HomeScreen: Starting to load initial data...');
    final productService = Provider.of<ProductService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);

    try {
      print('🏠 HomeScreen: Fetching categories, filter options, and cart data...');
      // Load categories, filter options, and cart data
      await Future.wait([
        productService.fetchFilterOptions(),
        productService.fetchCategories(),
        cartService.fetchCart(),
      ]);

      print('🏠 HomeScreen: Categories loaded: ${productService.categories.length}');
      if (mounted && productService.categories.isNotEmpty) {
        // Set first category as selected
        productService.setSelectedCategory(productService.categories.first);
        productService.resetPagination();
        
        // Load first category products immediately
        await productService.fetchProductsByCollection(
          productService.categories.first.handle,
          refresh: true,
        );
        
        print('🏠 HomeScreen: Products loaded for first category: ${productService.products.length}');
        // Cache the first category products
        setState(() {
          _currentCategoryHandle = productService.categories.first.handle;
          _categoryProductsCache[productService.categories.first.handle] = 
              List.from(productService.products);
          _preloadedCategories.add(productService.categories.first.handle);
        });
        
        // Start preloading other categories in background
        _preloadOtherCategories(productService);
        
        print('🏠 HomeScreen: Initial data loading completed successfully');
      }
    } catch (e) {
      print('❌ HomeScreen Error loading data: $e');
    }
  }

  Future<void> _preloadOtherCategories(ProductService productService) async {
    if (_isPreloadingCategories) return;
    
    setState(() {
      _isPreloadingCategories = true;
    });
    
    print('🔄 HomeScreen: Starting to preload other categories...');
    
    // Get categories that haven't been preloaded yet
    final categoriesToPreload = productService.categories
        .where((category) => !_preloadedCategories.contains(category.handle))
        .toList();
    
    for (final category in categoriesToPreload) {
      if (!mounted) break;
      
      try {
        print('🔄 HomeScreen: Preloading category: ${category.title}');
        
        // Create a temporary service instance to avoid interfering with current UI
        final tempProducts = <Product>[];
        
        // Fetch products for this category
        final products = await productService.fetchProductsByCollectionBackground(
          category.handle,
        );
        
        if (mounted && products.isNotEmpty) {
          setState(() {
            _categoryProductsCache[category.handle] = List.from(products);
            _preloadedCategories.add(category.handle);
          });
          print('🔄 HomeScreen: Preloaded ${products.length} products for ${category.title}');
        }
        
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 500));
        
      } catch (e) {
        print('❌ HomeScreen: Error preloading category ${category.title}: $e');
        // Continue with next category even if one fails
      }
    }
    
    setState(() {
      _isPreloadingCategories = false;
    });
    
    print('🔄 HomeScreen: Finished preloading categories. Total cached: ${_preloadedCategories.length}');
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

  Future<void> _switchCategory(ProductCategory category, ProductService productService) async {
    print('🔄 HomeScreen: Switching to category: ${category.title} (${category.handle})');
    if (productService.selectedCategory?.id == category.id) {
      print('🔄 HomeScreen: Category already selected, skipping...');
      return;
    }

    // Check if we have preloaded/cached products for this category
    if (_categoryProductsCache.containsKey(category.handle) && _categoryProductsCache[category.handle]!.isNotEmpty) {
      print('🔄 HomeScreen: Using preloaded products for ${category.title} (${_categoryProductsCache[category.handle]!.length} products)');
      
      // Instant switch - no loading state needed
      setState(() {
        _currentCategoryHandle = category.handle;
      });
      productService.setSelectedCategory(category);
      
      // Set cached products instantly
      productService.products.clear();
      productService.products.addAll(_categoryProductsCache[category.handle]!);
      
      // Update UI immediately
      if (mounted) {
        setState(() {});
      }
      
      print('🔄 HomeScreen: Instant category switch completed for ${category.title}');
    } else {
      print('🔄 HomeScreen: Products not preloaded for ${category.title}, loading now...');
      
      // Show loading state only if data is not preloaded
      setState(() {
        _isLoadingMore = true;
      });
      
      try {
        productService.setSelectedCategory(category);
        productService.resetPagination();
        await productService.fetchProductsByCollection(category.handle, refresh: true);
        
        print('🔄 HomeScreen: Loaded ${productService.products.length} products for ${category.title}');
        
        // Cache the loaded products for future instant access
        setState(() {
          _currentCategoryHandle = category.handle;
          _categoryProductsCache[category.handle] = List.from(productService.products);
          _preloadedCategories.add(category.handle);
          _isLoadingMore = false;
        });
        
        print('🔄 HomeScreen: Category switch completed successfully for ${category.title}');
      } catch (e) {
        print('❌ HomeScreen Error switching category: $e');
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ HomeScreen: Building widget...');
    // Get authentication service and guard
    final authService = Provider.of<AuthService>(context);
    final authGuard = Provider.of<AuthGuardService>(context, listen: false);
    final productService = Provider.of<ProductService>(context);
    
    // Show username if logged in
    final userName = authService.isAuthenticated && authService.currentUser != null 
        ? authService.currentUser!.name 
        : "Guest";
    
    print('🏗️ HomeScreen: User: $userName, Categories: ${productService.categories.length}, Loading: ${productService.isLoadingCategories}');
    
    // If categories are not loaded yet, show loading screen
    if (productService.categories.isEmpty && productService.isLoadingCategories) {
      print('🏗️ HomeScreen: Showing loading screen - categories not loaded');
      return Scaffold(
        appBar: AppBar(
          title: Text('Products'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              backgroundImage: authService.isAuthenticated && 
                              authService.currentUser?.avatarUrl != null && 
                              authService.currentUser!.avatarUrl!.isNotEmpty
                  ? NetworkImage(authService.currentUser!.avatarUrl!) as ImageProvider
                  : null,
              child: (authService.isAuthenticated && 
                     authService.currentUser?.avatarUrl != null && 
                     authService.currentUser!.avatarUrl!.isNotEmpty) 
                  ? null 
                  : const Icon(Icons.person, size: 20, color: Colors.grey),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello,',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                Text(
                  userName,
                  style: AppStyles.bodyText.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            // Cart icon with badge
            Consumer<CartService>(
              builder: (context, cartService, _) {
                final cartCount = cartService.itemCount;
                
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.of(context).pushNamed(Routes.CART);
                      },
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            cartCount > 9 ? '9+' : cartCount.toString(),
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: productService.categories.isEmpty
          ? Center(
              child: productService.error.isNotEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(productService.error),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshProducts,
                          child: const Text('Try Again'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            )
          : _buildMainContent(productService),
        bottomNavigationBar: const SharedBottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildMainContent(ProductService productService) {
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

    // Build scrollable content with carousel sections and products
    return _buildScrollableContent(productService);
  }

  Widget _buildScrollableContent(ProductService productService) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Promotional carousel
        const SliverToBoxAdapter(
          child: PromotionalCarousel(),
        ),
        // Quick actions
        const SliverToBoxAdapter(
          child: QuickActions(),
        ),
        // Flash sale section
        const SliverToBoxAdapter(
          child: FlashSaleSection(),
        ),
        // Trending section
        const SliverToBoxAdapter(
          child: TrendingSection(),
        ),
        // Category tabs and products grid
        SliverToBoxAdapter(
          child: CategoryProductsSection(
            categoryProductsCache: _categoryProductsCache,
            currentCategoryHandle: _currentCategoryHandle,
            onCategorySwitch: _switchCategory,
          ),
        ),
      ],
    );
  }
}
