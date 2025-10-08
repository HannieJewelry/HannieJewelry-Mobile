import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/collections_service.dart';
import '../services/product_detail_service.dart';
import '../widgets/product_detail_widget.dart';
import '../models/product_detail_model.dart';
import '../../../core/constants/app_colors.dart';

class ProductCollectionsScreen extends StatefulWidget {
  final String collectionHandle;
  final String? collectionTitle;

  const ProductCollectionsScreen({
    Key? key,
    required this.collectionHandle,
    this.collectionTitle,
  }) : super(key: key);

  @override
  State<ProductCollectionsScreen> createState() => _ProductCollectionsScreenState();
}

class _ProductCollectionsScreenState extends State<ProductCollectionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedVendor = 'all';
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final collectionsService = Provider.of<CollectionsService>(context, listen: false);
    collectionsService.getCollectionProducts(widget.collectionHandle);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final collectionsService = Provider.of<CollectionsService>(context, listen: false);
      if (collectionsService.hasMorePages && !collectionsService.isLoading) {
        collectionsService.loadNextPage(widget.collectionHandle);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.collectionTitle ?? 'Collection',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final collectionsService = Provider.of<CollectionsService>(context, listen: false);
              collectionsService.refreshProducts(widget.collectionHandle);
            },
          ),
        ],
      ),
      body: Consumer<CollectionsService>(
        builder: (context, collectionsService, child) {
          if (collectionsService.isLoading && collectionsService.allProducts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (collectionsService.error != null && collectionsService.allProducts.isEmpty) {
            return _buildErrorState(collectionsService.error!);
          }

          return Column(
            children: [
              _buildSearchAndFilters(collectionsService),
              _buildProductStats(collectionsService),
              Expanded(
                child: _buildProductGrid(collectionsService),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(CollectionsService collectionsService) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
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
          
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', _selectedFilter),
                const SizedBox(width: 8),
                _buildFilterChip('In Stock', 'available', _selectedFilter),
                const SizedBox(width: 8),
                ...collectionsService.getUniqueVendors().map((vendor) =>
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(vendor, vendor, _selectedVendor, isVendor: true),
                  ),
                ),
                ...collectionsService.getUniqueProductTypes().map((type) =>
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(type, type, _selectedType, isType: true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue, {bool isVendor = false, bool isType = false}) {
    final isSelected = selectedValue == value;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (isVendor) {
            _selectedVendor = selected ? value : 'all';
          } else if (isType) {
            _selectedType = selected ? value : 'all';
          } else {
            _selectedFilter = selected ? value : 'all';
          }
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildProductStats(CollectionsService collectionsService) {
    final filteredProducts = _getFilteredProducts(collectionsService);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            '${filteredProducts.length} products',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (collectionsService.currentResult != null) ...[
            Text(
              'Page ${collectionsService.currentPage}/${collectionsService.currentResult!.totalPages}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductGrid(CollectionsService collectionsService) {
    final filteredProducts = _getFilteredProducts(collectionsService);

    if (filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await collectionsService.refreshProducts(widget.collectionHandle);
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredProducts.length + (collectionsService.hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filteredProducts.length) {
            // Loading indicator for pagination
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final product = filteredProducts[index];
          return ProductDetailWidget(
            productHandle: product.handle,
            isCompact: false,
            onTap: () {
              _showProductDetail(product);
            },
          );
        },
      ),
    );
  }

  List<ProductDetail> _getFilteredProducts(CollectionsService collectionsService) {
    var products = collectionsService.allProducts;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      products = collectionsService.searchProducts(_searchQuery);
    }

    // Apply availability filter
    if (_selectedFilter == 'available') {
      products = products.where((p) => p.available).toList();
    }

    // Apply vendor filter
    if (_selectedVendor != 'all') {
      products = products.where((p) => p.vendor == _selectedVendor).toList();
    }

    // Apply type filter
    if (_selectedType != 'all') {
      products = products.where((p) => p.productType == _selectedType).toList();
    }

    return products;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all' || _selectedVendor != 'all' || _selectedType != 'all'
                  ? 'No products found'
                  : 'No products yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all' || _selectedVendor != 'all' || _selectedType != 'all'
                  ? 'Try changing filters or search keywords'
                  : 'This collection has no products yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'all' || _selectedVendor != 'all' || _selectedType != 'all') ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedFilter = 'all';
                    _selectedVendor = 'all';
                    _selectedType = 'all';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Cannot load products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetail(ProductDetail product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Product detail content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image
                      if (product.mainImageUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(
                              product.mainImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey[400],
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Product title and favorite button
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.displayTitle,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Consumer<ProductDetailService>(
                            builder: (context, productDetailService, child) {
                              final isFavorite = productDetailService.isFavorite(product.id);
                              return IconButton(
                                onPressed: () {
                                  productDetailService.toggleFavorite(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isFavorite ? 'Removed from favorites' : 'Added to favorites',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.grey[600],
                                  size: 28,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      
                      // Price
                      Text(
                        product.priceRange,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Product info
                      _buildProductInfoRow('Vendor', product.vendor),
                      _buildProductInfoRow('Product Type', product.productType),
                      _buildProductInfoRow('Status', product.available ? 'In Stock' : 'Out of Stock'),
                      if (product.hasVariants)
                        _buildProductInfoRow('Variants', '${product.variants.length} options'),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      if (product.bodyHtml.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.bodyHtml.replaceAll(RegExp(r'<[^>]*>'), ''),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Variants
                      if (product.hasVariants) ...[
                        const Text(
                          'Variants',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...product.variants.map((variant) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(variant.title),
                            subtitle: Text('${variant.price.toStringAsFixed(0)} VND'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: variant.available ? Colors.green[100] : Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                variant.available ? 'In Stock' : 'Out of Stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: variant.available ? Colors.green[700] : Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
