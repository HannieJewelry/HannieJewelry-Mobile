import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../models/product_model.dart';
import '../../../features/cart/services/cart_service.dart';
import '../../../features/cart/models/cart_model.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int quantity = 1;
  bool _isInCart = false;
  int _cartQuantity = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkIfInCart();
  }

  void _checkIfInCart() {
    final cartService = Provider.of<CartService>(context, listen: true);
    final foundItem = cartService.items.firstWhere(
      (item) => item.productId == widget.product.id,
      orElse: () => CartItem(
        id: '',
        handle: '',
        title: '',
        productId: '',
        productTitle: '',
        price: 0,
        priceOriginal: 0,
        linePrice: 0,
        linePriceOriginal: 0,
        quantity: 0,
        variantId: 0,
      ),
    );

    if (foundItem.productId.isNotEmpty) {
      setState(() {
        _isInCart = true;
        _cartQuantity = foundItem.quantity;
      });
    } else {
      setState(() {
        _isInCart = false;
        _cartQuantity = 0;
      });
    }
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity < 1) return;

    final cartService = Provider.of<CartService>(context, listen: false);
    final foundItem = cartService.items.firstWhere(
      (item) => item.productId == widget.product.id,
      orElse: () => CartItem(
        id: '',
        handle: '',
        title: '',
        productId: '',
        productTitle: '',
        price: 0,
        priceOriginal: 0,
        linePrice: 0,
        linePriceOriginal: 0,
        quantity: 0,
        variantId: 0,
      ),
    );

    if (foundItem.productId.isNotEmpty) {
      cartService.updateQuantity(foundItem.id, newQuantity).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated quantity to $newQuantity'),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 70, left: 15, right: 15),
          ),
        );
      });
    } else if (newQuantity > 0) {
      _addToCartWithQuantity(newQuantity);
    }
  }

  void _addToCartWithQuantity(int qty) {
    final cartService = Provider.of<CartService>(context, listen: false);
    
    // Get product info
    final String productId = widget.product.id;
    final String productName = widget.product.title;
    final double productPrice = widget.product.price;
    final String imageUrl = widget.product.image?.src ?? 
                           (widget.product.images.isNotEmpty ? widget.product.images.first.src : 'assets/images/placeholder.png');
    
    // Add product with quantity
    final variantId = widget.product.variants.isNotEmpty ? widget.product.variants.first.id : null;
    
    cartService.addItem(
      variantId ?? productId, 
      productName, 
      productPrice, 
      imageUrl,
      quantity: qty
    ).then((_) {
      // Call the parent callback to handle any additional logic
      widget.onAddToCart();
      
      // Show success message with shorter duration
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.title} added to cart'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 70, left: 15, right: 15),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => Navigator.pushNamed(context, Routes.CART),
          ),
        ),
      );
    }).catchError((error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item to cart'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 70, left: 15, right: 15),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
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
                    _buildProductImage(),
                    
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
                    if (!widget.product.available)
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
                    widget.product.title,
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
                        widget.product.formattedPrice,
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

  Widget _buildProductImage() {
    final String? imageUrl = widget.product.image?.src ?? 
                            (widget.product.images.isNotEmpty ? widget.product.images.first.src : null);
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            AppConfig.placeholderImage,
            fit: BoxFit.cover,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else {
      return Image.asset(
        AppConfig.placeholderImage,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildCartControls() {
    if (!widget.product.available) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Out of Stock',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      );
    }
    
    // If product is in cart, show quantity controls
    if (_isInCart) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 90), // Limit width to avoid overflow
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          // children: [
          //   _buildQuantityButton(
          //     icon: Icons.remove,
          //     onTap: () => _updateQuantity(_cartQuantity - 1),
          //   ),
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 4),
          //     child: Text(
          //       '$_cartQuantity',
          //       style: const TextStyle(
          //         fontWeight: FontWeight.bold,
          //         fontSize: 12,
          //       ),
          //     ),
          //   ),
          //   _buildQuantityButton(
          //     icon: Icons.add,
          //     onTap: () => _updateQuantity(_cartQuantity + 1),
          //   ),
          // ],
        ),
      );
    }
    
    // Hide the add button and return an empty SizedBox
    return const SizedBox.shrink();
  }
  
  // Helper methods for flat UI design
  bool _hasDiscount() {
    if (widget.product.variants.isEmpty) return false;
    final variant = widget.product.variants.first;
    return variant.compareAtPriceAsDouble > variant.priceAsDouble && variant.compareAtPriceAsDouble > 0;
  }

  int _getDiscountPercentage() {
    if (!_hasDiscount()) return 0;
    final variant = widget.product.variants.first;
    final originalPrice = variant.compareAtPriceAsDouble;
    final currentPrice = variant.priceAsDouble;
    return ((originalPrice - currentPrice) / originalPrice * 100).round();
  }

  String _getOriginalFormattedPrice() {
    if (widget.product.variants.isEmpty) return '';
    final originalPrice = widget.product.variants.first.compareAtPriceAsDouble;
    return '${originalPrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}đ';
  }

  int _getSoldCount() {
    // Using soleQuantity as sold count - you may want to adjust this based on your data structure
    return widget.product.soleQuantity;
  }
}
