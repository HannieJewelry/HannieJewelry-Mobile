import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/product_detail_service.dart';
import '../widgets/product_detail_widget.dart';
import '../../../core/constants/app_colors.dart';
import 'product_collections_screen.dart';

class FavoriteProductsScreen extends StatefulWidget {
  const FavoriteProductsScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteProductsScreen> createState() => _FavoriteProductsScreenState();
}

class _FavoriteProductsScreenState extends State<FavoriteProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Favorite Products',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Favorites'),
            Tab(text: 'Recently Viewed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_outlined),
            onPressed: () {
              _showCollectionsDemo();
            },
            tooltip: 'View demo collection',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFavoriteTab(),
                _buildRecentlyViewedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteTab() {
    return Consumer<ProductDetailService>(
      builder: (context, productService, child) {
        var products = productService.favoriteProducts;
        
        // Filter products based on search query
        if (_searchQuery.isNotEmpty) {
          products = productService.searchInCache(_searchQuery)
              .where((p) => productService.isFavorite(p.id))
              .toList();
        }

        if (products.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border,
            title: _searchQuery.isEmpty 
                ? 'No favorite products yet'
                : 'No products found',
            subtitle: _searchQuery.isEmpty
                ? 'Add products to your favorites to see them here'
                : 'Try a different search term',
          );
        }

        return _buildProductGrid(products);
      },
    );
  }

  Widget _buildRecentlyViewedTab() {
    return Consumer<ProductDetailService>(
      builder: (context, productService, child) {
        var products = productService.recentlyViewedProducts;
        
        // Filter products based on search query
        if (_searchQuery.isNotEmpty) {
          products = productService.searchInCache(_searchQuery)
              .where((p) => productService.recentlyViewedProducts.any((r) => r.id == p.id))
              .toList();
        }

        if (products.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: _searchQuery.isEmpty 
                ? 'No recently viewed products'
                : 'No products found',
            subtitle: _searchQuery.isEmpty
                ? 'Products you view will appear here'
                : 'Try a different search term',
            actionButton: _searchQuery.isEmpty
                ? ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Explore Products'),
                  )
                : null,
          );
        }

        return Column(
          children: [
            // Clear history button
            if (products.isNotEmpty && _searchQuery.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: TextButton.icon(
                  onPressed: () {
                    _showClearHistoryDialog(context);
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Viewing History'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[600],
                  ),
                ),
              ),
            
            Expanded(child: _buildProductGrid(products)),
          ],
        );
      },
    );
  }

  Widget _buildProductGrid(List products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductDetailWidget(
          productHandle: product.handle,
          isCompact: false,
          onTap: () {
            // Navigate to product detail screen
            // Navigator.pushNamed(context, '/product-detail', arguments: product.handle);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('View details: ${product.displayTitle}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? actionButton,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 24),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Viewing History'),
          content: const Text('Are you sure you want to clear all your product viewing history?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<ProductDetailService>(context, listen: false)
                    .clearRecentlyViewed();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Viewing history has been cleared'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showCollectionsDemo() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Product Collections Demo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select a collection to view the integrated API demo:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.diamond_outlined, color: AppColors.primary),
                title: const Text('Luxury Jewelry'),
                subtitle: const Text('details-product'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductCollectionsScreen(
                        collectionHandle: 'details-product',
                        collectionTitle: 'Luxury Jewelry',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: AppColors.primary),
                title: const Text('Products with Images'),
                subtitle: const Text('valid-product-image'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductCollectionsScreen(
                        collectionHandle: 'valid-product-image',
                        collectionTitle: 'Products with Images',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'API: /api/client/collections/{handle}/products',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
