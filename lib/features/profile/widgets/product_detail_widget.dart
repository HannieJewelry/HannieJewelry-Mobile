import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_detail_model.dart';
import '../services/product_detail_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class ProductDetailWidget extends StatelessWidget {
  final String productHandle;
  final VoidCallback? onTap;
  final bool showFavoriteButton;
  final bool isCompact;

  const ProductDetailWidget({
    Key? key,
    required this.productHandle,
    this.onTap,
    this.showFavoriteButton = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductDetailService>(
      builder: (context, productService, child) {
        return FutureBuilder<ProductDetail?>(
          future: productService.getProductDetail(productHandle),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingCard();
            }

            if (snapshot.hasError || snapshot.data == null) {
              return _buildErrorCard(snapshot.error?.toString());
            }

            final product = snapshot.data!;
            return _buildProductCard(context, product, productService);
          },
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: isCompact ? 120 : 200,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String? error) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: isCompact ? 120 : 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Cannot load product',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 4),
              Text(
                error,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductDetail product, ProductDetailService productService) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: isCompact ? 120 : 200,
          padding: const EdgeInsets.all(12),
          child: isCompact ? _buildCompactLayout(context, product, productService) 
                          : _buildFullLayout(context, product, productService),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, ProductDetail product, ProductDetailService productService) {
    return Row(
      children: [
        // Product Image
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 80,
            height: 80,
            color: Colors.grey[200],
            child: product.mainImageUrl.isNotEmpty
                ? Image.network(
                    product.mainImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),
        ),
        const SizedBox(width: 12),
        
        // Product Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.displayTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (product.vendor.isNotEmpty) ...[
                Text(
                  product.vendor,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                product.priceRange,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.available ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.available ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        fontSize: 10,
                        color: product.available ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (showFavoriteButton)
                    _buildFavoriteButton(product, productService),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context, ProductDetail product, ProductDetailService productService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              color: Colors.grey[200],
              child: product.mainImageUrl.isNotEmpty
                  ? Image.network(
                      product.mainImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Product Info
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showFavoriteButton)
                    _buildFavoriteButton(product, productService),
                ],
              ),
              const SizedBox(height: 4),
              if (product.vendor.isNotEmpty) ...[
                Text(
                  product.vendor,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                product.priceRange,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.available ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.available ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        fontSize: 10,
                        color: product.available ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (product.hasVariants) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.variants.length} variants',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton(ProductDetail product, ProductDetailService productService) {
    final isFavorite = productService.isFavorite(product.id);
    
    return GestureDetector(
      onTap: () => productService.toggleFavorite(product),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey[400],
        size: 32,
      ),
    );
  }
}

class ProductDetailListWidget extends StatelessWidget {
  final List<ProductDetail> products;
  final String title;
  final bool isCompact;
  final VoidCallback? onSeeAll;

  const ProductDetailListWidget({
    Key? key,
    required this.products,
    required this.title,
    this.isCompact = true,
    this.onSeeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: const Text('See All'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: isCompact ? 140 : 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                width: isCompact ? 280 : 200,
                margin: EdgeInsets.only(
                  right: index < products.length - 1 ? 12 : 0,
                ),
                child: ProductDetailWidget(
                  productHandle: product.handle,
                  isCompact: isCompact,
                  onTap: () {
                    // Navigate to product detail screen
                    // Navigator.pushNamed(context, '/product-detail', arguments: product.handle);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
