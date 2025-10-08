import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/cart_badge.dart';
import '../../../routes/app_routes.dart';
import '../../cart/screens/cart_screen_fixed.dart';
import '../../cart/services/cart_service.dart';
import '../models/product_model.dart';
import '../models/product_category_model.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';


class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProductCategory> _categories = [];
  bool _isLoadingCategories = true;
  String _selectedCategory = '';
  final ScrollController _scrollController = ScrollController();
  
  // Sort state
  String _sortOption = 'Newest';
  final List<String> _sortOptions = ['Newest', 'Price Low to High', 'Price High to Low'];
  
  // Filter variables
  final List<String> _productTypes = [];
  final Set<String> _selectedProductTypes = {};
  RangeValues _priceRange = const RangeValues(0, 10000000);
  
  @override
  void initState() {
    super.initState();
    // Use Future.microtask to delay the API call until after the build is complete
    Future.microtask(() {
      _loadCategories();
      _loadProducts();
    });
    
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final productService = Provider.of<ProductService>(context, listen: false);
      if (!productService.isLoadingMore && productService.hasMoreProducts) {
        productService.loadMoreProducts();
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    
    try {
      final productService = Provider.of<ProductService>(context, listen: false);
      // Explicitly call fetchCategories to ensure we get the latest data from the API
      final categories = await productService.fetchCategories();
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
          if (categories.isNotEmpty) {
            _selectedCategory = categories[0].title;
            _tabController = TabController(length: categories.length, vsync: this);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _loadProducts() async {
    final productService = Provider.of<ProductService>(context, listen: false);
    if (_categories.isNotEmpty) {
      final firstCategory = _categories.first;
      await productService.fetchProductsByCollection(firstCategory.handle, refresh: true);
    }
    
    // Extract unique product types from products
    if (productService.products.isNotEmpty) {
      final types = productService.products
          .map((p) => p.productType)
          .where((type) => type.isNotEmpty)
          .toSet()
          .toList();
      
      if (mounted) {
        setState(() {
          _productTypes.clear();
          _productTypes.addAll(types);
        });
      }
    }
  }

  Future<void> _refreshProducts() async {
    final productService = Provider.of<ProductService>(context, listen: false);
    if (_categories.isNotEmpty) {
      // Find the category that matches the selected category name
      final selectedCategoryObj = _categories.firstWhere(
        (cat) => cat.title == _selectedCategory,
        orElse: () => _categories.first,
      );
      await productService.fetchProductsByCollection(selectedCategoryObj.handle, refresh: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    if (_categories.isNotEmpty) {
      _tabController.dispose();
    }
    super.dispose();
  }

  // Show filter dialog
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Filter',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 48), // For balance with back button
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Price range
                      const Text(
                        'Price Range (VND)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Minimum',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('—'),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Maximum',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Product type
                      if (_productTypes.isNotEmpty) ...[
                        const Text(
                          'Product Type',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _productTypes.map((type) {
                            final isSelected = _selectedProductTypes.contains(type);
                            return FilterChip(
                              label: Text(type),
                              selected: isSelected,
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.primary.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                ),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedProductTypes.add(type);
                                  } else {
                                    _selectedProductTypes.remove(type);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Apply filters
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Reset button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedProductTypes.clear();
                              _priceRange = const RangeValues(0, 10000000);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
        },
      ),
    );
  }
  
  // Apply filters
  Future<void> _applyFilters() async {
    final productService = Provider.of<ProductService>(context, listen: false);
    
    // Reset pagination and fetch products with filters
    productService.resetPagination();
    
    if (_categories.isNotEmpty) {
      // Find the category that matches the selected category name
      final selectedCategoryObj = _categories.firstWhere(
        (cat) => cat.title == _selectedCategory,
        orElse: () => _categories.first,
      );
      await productService.fetchProductsByCollection(selectedCategoryObj.handle, refresh: true);
    }
  }

  // Apply sort
  Future<void> _applySorting(String sortOption) async {
    String sortBy;
    String direction;
    
    switch (sortOption) {
      case 'Newest':
        sortBy = 'createdAt';
        direction = 'DESC';
        break;
      case 'Price Low to High':
        sortBy = 'price';
        direction = 'ASC';
        break;
      case 'Price High to Low':
        sortBy = 'price';
        direction = 'DESC';
        break;
      default:
        sortBy = 'createdAt';
        direction = 'DESC';
    }
    
    setState(() {
      _sortOption = sortOption;
    });
    
    // Since we've updated to use the new API, we need to handle sorting differently
    // This is a placeholder for now - the actual implementation would depend on your backend
    final productService = Provider.of<ProductService>(context, listen: false);
    if (_categories.isNotEmpty) {
      final selectedCategoryObj = _categories.firstWhere(
        (cat) => cat.title == _selectedCategory,
        orElse: () => _categories.first,
      );
      await productService.fetchProductsByCollection(selectedCategoryObj.handle, refresh: true);
    }
  }

  // Search products
  Future<void> _searchProducts(String value) async {
    if (value.isEmpty) {
      _refreshProducts();
      return;
    }
    
    // Since we've updated to use the new API, we need to handle search differently
    // This is a placeholder for now - the actual implementation would depend on your backend
    final productService = Provider.of<ProductService>(context, listen: false);
    if (_categories.isNotEmpty) {
      final selectedCategoryObj = _categories.firstWhere(
        (cat) => cat.title == _selectedCategory,
        orElse: () => _categories.first,
      );
      await productService.fetchProductsByCollection(selectedCategoryObj.handle, refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          Consumer<CartService>(
            builder: (context, cartService, child) {
              return CartBadge(
                count: cartService.itemCount,
                onPressed: () {
                  Navigator.pushNamed(context, Routes.CART);
                },
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  await _searchProducts(value);
                }
              },
            ),
          ),
          
          // Filter and Sort buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFilterDialog,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filter'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 40),
                    onSelected: _applySorting,
                    itemBuilder: (context) {
                      return _sortOptions.map((option) {
                        return PopupMenuItem<String>(
                          value: option,
                          child: Row(
                            children: [
                              Text(option),
                              const Spacer(),
                              if (_sortOption == option)
                                Icon(Icons.check, color: AppColors.primary),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    child: OutlinedButton.icon(
                      onPressed: null, // This is handled by PopupMenuButton
                      icon: const Icon(Icons.sort),
                      label: const Text('Sort'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Product grid
          Expanded(
            child: Consumer<ProductService>(
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
                
                if (productService.products.isEmpty) {
                  return const Center(child: Text('No products found'));
                }
                
                return RefreshIndicator(
                  onRefresh: _refreshProducts,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: productService.products.length + (productService.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == productService.products.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final product = productService.products[index];
                      return _buildProductCard(product);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images.first.src,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/placeholder.png',
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/placeholder.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            
            // Product info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (product.vendor.isNotEmpty)
                    Text(
                      product.vendor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)} VND',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 4),
                      // Remove the compareAtPrice references since it's not in our Product model
                      Expanded(
                        child: IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.primary),
                          onPressed: () {
                            final cartService = Provider.of<CartService>(context, listen: false);
                            if (product.variants.isNotEmpty) {
                              cartService.addItem(
                                product.variants[0].id as String,
                                product.title,
                                product.variants[0].price as double,
                                product.images.isNotEmpty ? product.images.first.src : '',
                                quantity: 1,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added ${product.title} to cart'),
                                  duration: const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: 'VIEW CART',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const CartScreen()),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(productHandle: product.handle),
      ),
    );
  }
}