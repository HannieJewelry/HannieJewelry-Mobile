import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../products/models/product_model.dart';
import '../../products/screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.image?.src ?? 
      (product.images.isNotEmpty ? product.images.first.src : '');
      
    return GestureDetector(
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with badges
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/placeholder.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/placeholder.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                    
                    // Discount badge (top-right)
                    if (_hasDiscount())
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${_getDiscountPercentage()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Out of stock overlay
                    if (!product.available)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        alignment: Alignment.center,
                        child: const Text(
                          'Hết hàng',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Title
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Price section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current price
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      
                      // Original price and discount
                      if (_hasDiscount())
                        Row(
                          children: [
                            Text(
                              _getOriginalFormattedPrice(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '-${_getDiscountPercentage()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Sold count
                  Text(
                    'Đã bán ${_getSoldCount()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for flat UI design
  bool _hasDiscount() {
    if (product.variants.isEmpty) return false;
    final variant = product.variants.first;
    return variant.compareAtPriceAsDouble > variant.priceAsDouble && variant.compareAtPriceAsDouble > 0;
  }

  int _getDiscountPercentage() {
    if (!_hasDiscount()) return 0;
    final variant = product.variants.first;
    final originalPrice = variant.compareAtPriceAsDouble;
    final currentPrice = variant.priceAsDouble;
    return ((originalPrice - currentPrice) / originalPrice * 100).round();
  }

  String _getOriginalFormattedPrice() {
    if (product.variants.isEmpty) return '';
    final originalPrice = product.variants.first.compareAtPriceAsDouble;
    return '${originalPrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}đ';
  }

  int _getSoldCount() {
    // Using soleQuantity as sold count - you may want to adjust this based on your data structure
    return product.soleQuantity;
  }
}
