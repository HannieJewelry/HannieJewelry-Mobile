import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Import for TimeoutException
import '../../../core/constants/app_colors.dart';

import '../../checkout/screens/checkout_screen.dart';
import '../../home/screens/home_screen.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/safe_back_handler.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Load cart data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCartData();
    });
  }
  
  Future<void> _loadCartData() async {
    final cartService = Provider.of<CartService>(context, listen: false);
    
    // Set context for error messages
    cartService.setContext(context);
    
    try {
      await cartService.fetchCart();
    } catch (e) {
      // Error handling is now done in the cart service
    }
  }
  
  // Safe navigation method to prevent black screen or app exit
  void _handleBackNavigation() {
    // Check if we can pop safely
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If we can't pop (we're the only screen in stack), navigate to home instead
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final cart = cartService.cart;
    final items = cartService.items;
    final bool isInitialLoading = cartService.isLoading && items.isEmpty;

    return SafeBackHandler(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Your Cart',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackNavigation,
          ),
          actions: [
            if (items.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _showClearCartConfirmation(context, cartService),
                tooltip: 'Clear cart',
              ),
            // Refresh button for cart
            IconButton(
              icon: cartService.isLoading 
                ? SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  )
                : const Icon(Icons.refresh),
              onPressed: cartService.isLoading ? null : _loadCartData,
              tooltip: 'Refresh cart',
            ),
          ],
        ),
        body: isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add items to get started',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _handleBackNavigation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Continue Shopping'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (ctx, i) => CartItemWidget(cartItem: items[i]),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  _formatCurrency(cartService.totalPrice),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Items',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                Text(
                                  '${cartService.itemCount} items',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Proceed to Checkout',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CheckoutScreen(),
                                  ),
                                );
                              },
                              isOutlined: false,
                              isFullWidth: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  void _showClearCartConfirmation(BuildContext context, CartService cartService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text('Are you sure you want to remove all products from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                
                // Show loading indicator
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final loadingSnackBar = SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2, 
                          color: Colors.white,
                        )
                      ),
                      const SizedBox(width: 16),
                      const Text('Removing all items...'),
                    ],
                  ),
                  duration: const Duration(seconds: 10), // Reduced timeout
                );
                
                scaffoldMessenger.showSnackBar(loadingSnackBar);
                
                try {
                  final result = await cartService.clear();
                  
                  // Always hide loading indicator
                  scaffoldMessenger.hideCurrentSnackBar();
                  
                  // Show appropriate message based on result
                  if (result) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('All products have been removed from your cart'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    
                    // Force refresh the cart data to ensure UI updates correctly
                    await cartService.fetchCart();
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: const Text('Unable to clear cart. Please try again later.'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                } catch (e) {
                  // Hide loading indicator
                  scaffoldMessenger.hideCurrentSnackBar();
                  // Show error message
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text('Không thể xóa giỏ hàng. Vui lòng thử lại sau.'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                  
                  // Force refresh the cart data
                  await cartService.fetchCart();
                }
              },
              child: Text(
                'Remove All',
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double price) {
    String priceString = price.toStringAsFixed(0);
    final result = StringBuffer();
    for (int i = 0; i < priceString.length; i++) {
      if ((priceString.length - i) % 3 == 0 && i > 0) {
        result.write('.');
      }
      result.write(priceString[i]);
    }
    return '${result.toString()} VND';
  }
}

class CartItemWidget extends StatelessWidget {
  final CartItem cartItem;

  const CartItemWidget({Key? key, required this.cartItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);
    // Check if the product is at max available stock
    final bool isOutOfStock = cartItem.quantity >= (cartItem.availableQuantity ?? 0);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Apply opacity to the whole card if out of stock
      color: isOutOfStock ? Colors.grey.shade100 : Colors.white,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Product image with reduced opacity if out of stock
                    Opacity(
                      opacity: isOutOfStock ? 0.5 : 1.0,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildProductImage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Product information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Apply reduced opacity to text if out of stock
                          Opacity(
                            opacity: isOutOfStock ? 0.7 : 1.0,
                            child: Text(
                              cartItem.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (cartItem.variant != null && cartItem.variant!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Apply reduced opacity to variant text if out of stock
                                Opacity(
                                  opacity: isOutOfStock ? 0.7 : 1.0,
                                  child: const Text(
                                    'Option: ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Opacity(
                                    opacity: isOutOfStock ? 0.7 : 1.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        cartItem.variant!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Apply reduced opacity to price if out of stock
                              Opacity(
                                opacity: isOutOfStock ? 0.7 : 1.0,
                                child: Text(
                                  _formatCurrency(cartItem.price),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              // Apply reduced opacity to total price if out of stock
                              Opacity(
                                opacity: isOutOfStock ? 0.7 : 1.0,
                                child: Text(
                                  'Total: ${_formatCurrency(cartItem.price * cartItem.quantity)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Show stock warning if out of stock
                          if (isOutOfStock) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Maximum available stock reached',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quantity controls and delete button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: cartItem.quantity > 1 ? () {
                              // Không hiển thị loading khi giảm số lượng
                              cartService.updateQuantity(
                                cartItem.id, 
                                cartItem.quantity - 1,
                                variant: cartItem.variant,
                              );
                            } : null,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${cartItem.quantity}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Disable add button if out of stock
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: isOutOfStock ? null : () {
                              if (cartItem.availableQuantity != null && cartItem.quantity >= cartItem.availableQuantity!) {
                                // Show snackbar for out of stock
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Maximum available stock reached for this product'),
                                  backgroundColor: Colors.red.shade700,
                                    duration: const Duration(seconds: 1), // Giảm thời gian hiển thị
                                  ),
                                );
                              } else {
                                // Không hiển thị loading khi tăng số lượng
                                cartService.updateQuantity(
                                  cartItem.id, 
                                  cartItem.quantity + 1,
                                  variant: cartItem.variant,
                                );
                              }
                            },
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmation(context, cartService);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Overlay badge for out of stock
          if (isOutOfStock)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Out of Stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    // Check if image URL is valid
    if (cartItem.image?.isEmpty ?? true || 
        cartItem.image?.startsWith('file:///') == true ||
        (Uri.tryParse(cartItem.image ?? '')?.hasAbsolutePath == false)) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 40,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Check if it's a network URL
    if (cartItem.image?.startsWith('http://') == true || cartItem.image?.startsWith('https://') == true) {
      return Image.network(
        cartItem.image!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 40,
                color: Colors.grey,
              ),
            ),
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
              strokeWidth: 2,
            ),
          );
        },
      );
    }

    // Check if it's an asset image
    if (cartItem.image?.startsWith('assets/') == true) {
      return Image.asset(
        cartItem.image!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 40,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    }

    // Default fallback
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, CartService cartService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Product'),
          content: const Text('Are you sure you want to remove this product from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Đóng hộp thoại ngay lập tức
                Navigator.of(context).pop();
                
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                try {
                  // Gọi removeItem - đã được cải thiện để cập nhật UI ngay lập tức
                final result = await cartService.removeItem(
                  cartItem.id,
                  variant: cartItem.variant,
                  ).timeout(const Duration(seconds: 10), onTimeout: () {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: const Text('Operation is taking longer than expected'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return false;
                  });
                
                  // Chỉ hiển thị thông báo lỗi nếu thất bại
                if (!result) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: const Text('Unable to remove product. Please try again.'),
                        backgroundColor: Colors.red.shade700,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // Chỉ hiển thị thông báo lỗi nếu có exception
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text('An error occurred. Please try again.'),
                      backgroundColor: Colors.red.shade700,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(
                'Remove',
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double price) {
    String priceString = price.toStringAsFixed(0);
    final result = StringBuffer();
    for (int i = 0; i < priceString.length; i++) {
      if ((priceString.length - i) % 3 == 0 && i > 0) {
        result.write('.');
      }
      result.write(priceString[i]);
    }
    return '${result.toString()} VND';
  }
}
