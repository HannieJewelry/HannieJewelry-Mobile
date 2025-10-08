import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode

import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../cart/screens/cart_screen_fixed.dart';
import '../../cart/services/cart_service.dart';
import '../../cart/models/cart_model.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
 // Added for Routes

class ProductDetailScreen extends StatefulWidget {
  final String productHandle;
  
  const ProductDetailScreen({
    Key? key,
    required this.productHandle,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  String _error = '';
  int _selectedVariantIndex = 0;
  int _quantity = 1;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  
  @override
  void initState() {
    super.initState();
    _loadProduct();
    
    // Set context for CartService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartService = Provider.of<CartService>(context, listen: false);
      cartService.setContext(context);
      
      // Refresh cart data to ensure accurate information
      cartService.refreshCart();
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final productService = Provider.of<ProductService>(context, listen: false);
      
      // Use the handle to fetch the product
      final product = await productService.fetchProductByHandle(widget.productHandle);
      
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
          
          // Set default selected variant to the first one if available
          if (product != null && product.variants.isNotEmpty) {
            _selectedVariantIndex = 0;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading product: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  void _incrementQuantity() {
    if (_product != null && _selectedVariantIndex < _product!.variants.length) {
      final variant = _product!.variants[_selectedVariantIndex];
      if (_quantity < variant.inventoryQuantity) {
        setState(() {
          _quantity++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum available quantity reached')),
        );
      }
    }
  }
  
  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }
  
  void _checkAuthAndAddToCart() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (!authService.isAuthenticated) {
      _showLoginRequired('add to cart');
      return;
    }
    
    _addToCart();
  }
  
  void _checkAuthAndBuyNow() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (!authService.isAuthenticated) {
      _showLoginRequired('buy now');
      return;
    }
    
    _buyNow();
  }
  
  void _showLoginRequired(String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: Text('You need to login to $action. Would you like to login now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
  void _addToCart() {
    if (_product == null || _product!.variants.isEmpty) return;

    final variant = _product!.variants[_selectedVariantIndex];
    final cartService = Provider.of<CartService>(context, listen: false);

    // Check if this variant is already in the cart
    final foundItem = cartService.items.firstWhere(
          (item) => item.variantId.toString() == variant.id.toString(),
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

    // Prepare properties to send with the cart item (color, size, etc.)
    final Map<String, dynamic> properties = {};
    for (final option in _product!.options) {
      final optionName = option.name.toLowerCase();
      if (optionName.contains('color') || optionName.contains('màu')) {
        if (_selectedVariantIndex < option.values.length) {
          properties['color'] = option.values[_selectedVariantIndex];
        }
      } else if (optionName.contains('size') ||
          optionName.contains('kích') ||
          optionName.contains('cỡ')) {
        if (_selectedVariantIndex < option.values.length) {
          properties['size'] = option.values[_selectedVariantIndex];
        }
      } else {
        if (_selectedVariantIndex < option.values.length) {
          properties[option.name.toLowerCase()] = option.values[_selectedVariantIndex];
        }
      }
    }

    if (kDebugMode) {
      print('📦 Adding variant to cart:');
      print('   Variant ID: ${variant.id}');
      print('   Properties: $properties');
    }

    if (foundItem.id.isNotEmpty) {
      final newQuantity = foundItem.quantity + _quantity;
      cartService.updateQuantity(foundItem.id, newQuantity);
    } else {
      cartService.addItem(
        variant.id,
        _product!.title,
        variant.priceAsDouble,
        _product!.images.isNotEmpty ? _product!.images.first.src : '',
        quantity: _quantity,
        variant: variant.title,
        properties: properties.isNotEmpty ? properties : null,
      );
    }
  }

  void _buyNow() {
    if (_product == null || _product!.variants.isEmpty) return;
    
    final variant = _product!.variants[_selectedVariantIndex];
    final cartService = Provider.of<CartService>(context, listen: false);
    
    // Check if this variant is already in the cart
    final foundItem = cartService.items.firstWhere(
      (item) => item.variantId.toString() == variant.id.toString(),
      orElse: () => CartItem(id: '', handle: '', title: '', productId: '', productTitle: '', price: 0, priceOriginal: 0, linePrice: 0, linePriceOriginal: 0, quantity: 0, variantId: 0),
    );

    // Prepare properties to send with the cart item (color, size, etc.)
    final Map<String, dynamic> properties = {};
    
    // Extract color, size, and other properties from the product options
    for (final option in _product!.options) {
      final optionName = option.name.toLowerCase();
      if (optionName.contains('color') || optionName.contains('màu')) {
        if (_selectedVariantIndex < option.values.length) {
          properties['color'] = option.values[_selectedVariantIndex];
        }
      } else if (optionName.contains('size') || 
                 optionName.contains('kích') || 
                 optionName.contains('cỡ')) {
        if (_selectedVariantIndex < option.values.length) {
          properties['size'] = option.values[_selectedVariantIndex];
        }
      } else {
        // Add any other option as a property
        if (_selectedVariantIndex < option.values.length) {
          properties[option.name.toLowerCase()] = option.values[_selectedVariantIndex];
        }
      }
    }
    
    if (kDebugMode) {
      print('📦 Buying variant:');
      print('   Variant ID: ${variant.id}');
      print('   Properties: $properties');
    }
    
    // Function to navigate to cart for checkout
    void navigateToCart() {
      Navigator.pushNamed(context, Routes.CART);
    }
    
    if (foundItem.id.isNotEmpty) {
      // If the variant is already in the cart, update the quantity
      final newQuantity = foundItem.quantity + _quantity;
      cartService.updateQuantity(foundItem.id, newQuantity).then((_) {
        // Navigate directly to cart for checkout
        navigateToCart();
      });
    } else {
      // Add item to cart first with correct variant and quantity
      cartService.addItem(
        variant.id,
        _product!.title,
        variant.priceAsDouble,
        _product!.images.isNotEmpty ? _product!.images.first.src : '',
        quantity: _quantity,
        variant: variant.title,
        properties: properties.isNotEmpty ? properties : null,
      ).then((_) {
        // Navigate directly to cart for checkout
        navigateToCart();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProduct,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _product == null
                  ? const Center(child: Text('Product not found'))
                  : _buildProductDetail(),
      bottomNavigationBar: _isLoading || _error.isNotEmpty || _product == null
          ? null
          : Consumer<CartService>(
              builder: (context, cartService, child) {
                if (cartService.itemCount == 0) {
                  return _buildBottomBar(); // Nếu giỏ hàng trống, hiển thị thanh nút Add to Cart / Buy Now
                }
                
                // Nếu giỏ hàng có sản phẩm, hiển thị tóm tắt giỏ hàng phía dưới
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBottomBar(), // Thanh nút Add to Cart / Buy Now vẫn hiển thị
                    _buildCartSummary(cartService), // Thanh tóm tắt giỏ hàng
                  ],
                );
              },
            ),
    );
  }

  // Thêm widget hiển thị tóm tắt giỏ hàng
  Widget _buildCartSummary(CartService cartService) {
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
                  '${_formatPriceWithCommas(cartService.totalPrice)}đ',
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
              child: const Center(
                child: Text(
                  'View cart',
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
  }
  
  // Helper để định dạng giá tiền với dấu phân cách hàng nghìn
  String _formatPriceWithCommas(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget _buildProductDetail() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image gallery with page indicator
          Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.width,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _product!.images.isNotEmpty ? _product!.images.length : 1,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    if (_product!.images.isEmpty) {
                      return Image.asset(
                        'assets/images/placeholder.png',
                        fit: BoxFit.cover,
                      );
                    }
                    return Image.network(
                      _product!.images[index].src,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/placeholder.png',
                          fit: BoxFit.cover,
                        );
                      },
                    );
                  },
                ),
              ),
              // Page indicator
              if (_product!.images.length > 1)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _product!.images.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? AppColors.primary
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị tiêu đề sản phẩm với xử lý đúng UTF-8
                Text(
                  _product!.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_product!.variants.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        _formatPrice(_product!.variants[_selectedVariantIndex].priceAsDouble),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_product!.variants[_selectedVariantIndex].compareAtPriceAsDouble > 
                          _product!.variants[_selectedVariantIndex].priceAsDouble)
                        Text(
                          _formatPrice(_product!.variants[_selectedVariantIndex].compareAtPriceAsDouble),
                          style: const TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'In Stock: ${_product!.variants[_selectedVariantIndex].inventoryQuantity}',
                    style: TextStyle(
                      color: _product!.variants[_selectedVariantIndex].inventoryQuantity > 0
                          ? Colors.green
                          : Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                
                const Divider(height: 32),
                
                // Product details
                const Text(
                  'Product Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Product code
                _buildDetailRow('Product Code', _extractProductCode(_product!.title)),
                
                // Product type
                if (_product!.productType.isNotEmpty)
                  _buildDetailRow('Product Type', _product!.productType),
                
                // Vendor
                if (_product!.vendor.isNotEmpty)
                  _buildDetailRow('Brand', _product!.vendor),
                
                // Options
                if (_product!.options.isNotEmpty)
                  ..._product!.options.map((option) => 
                    _buildDetailRow(option.name, option.values.join(', '))
                  ),
                
                const Divider(height: 32),
                
                // Product description
                if (_product!.bodyHtml.isNotEmpty) ...[
                  const Text(
                    'Product Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Html(data: _product!.bodyHtml),
                ],
                
                const SizedBox(height: 24),
                
                // Variants
                if (_product!.variants.length > 1) ...[
                  const Text(
                    'Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_product!.variants.length, (index) {
                      final variant = _product!.variants[index];
                      final isSelected = _selectedVariantIndex == index;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedVariantIndex = index;
                            // Reset quantity when variant changes
                            _quantity = 1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                ),
                              Text(
                                variant.title,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.primary : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Quantity selector
                Row(
                  children: [
                    const Text(
                      'Quantity:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _decrementQuantity,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(7),
                                bottomLeft: Radius.circular(7),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                child: const Icon(Icons.remove, size: 18),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _quantity.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _incrementQuantity,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(7),
                                bottomRight: Radius.circular(7),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                child: const Icon(Icons.add, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (_product!.variants.isNotEmpty)
                      Text(
                        '( ${_product!.variants[_selectedVariantIndex].inventoryQuantity} available )',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
  
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _checkAuthAndAddToCart,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add to Cart',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _checkAuthAndBuyNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Buy Now',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper methods to extract product information
  String _extractProductCode(String title) {
    // Extract product code from title (e.g., "Lắc tay LPTB 382" -> "LPTB 382")
    final RegExp regex = RegExp(r'([A-Z]+\s*\d+)');
    final match = regex.firstMatch(title);
    return match != null ? match.group(1)! : title;
  }
  
  String _extractMaterial(String description) {
    // Extract material info from description
    if (description.contains('AU585')) {
      return 'AU585';
    } else if (description.contains('AU750')) {
      return 'AU750';
    } else if (description.contains('Vàng') || description.contains('Gold')) {
      return 'Gold';
    }
    return 'No information';
  }
  
  String _extractWeight(String description) {
    // Extract weight info from description
    final RegExp regex = RegExp(r'(\d+[\.,]?\d*)\s*g');
    final match = regex.firstMatch(description);
    return match != null ? '≈${match.group(1)}g' : 'No information';
  }
  
  String _extractStoneType(String description) {
    // Extract stone type from description
    if (description.contains('Moissanite')) {
      return 'Moissanite';
    } else if (description.contains('Ruby')) {
      return 'Ruby';
    } else if (description.contains('Sapphire')) {
      return 'Sapphire';
    } else if (description.contains('Diamond')) {
      return 'Diamond';
    }
    return 'No information';
  }
  
  String _formatPrice(double price) {
    // Format price as currency
    return '\$${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }
}