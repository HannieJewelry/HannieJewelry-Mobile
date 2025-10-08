import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // Import for TimeoutException
import '../models/cart_model.dart';
import '../../../core/services/api_service.dart';

class CartService extends ChangeNotifier {
  final ApiService _apiService;
  Cart _cart = Cart.empty();
  bool _isLoading = false;
  String? _error;
  BuildContext? _context; // To show snackbars

  CartService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  // Getters
  Cart get cart => _cart;
  List<CartItem> get items => _cart.items;
  
  // Recalculate item count manually to ensure accuracy
  int get itemCount {
    int count = 0;
    for (var item in _cart.items) {
      count += item.quantity;
    }
    return count;
  }
  
  // Recalculate total price manually to ensure accuracy
  double get totalPrice {
    double total = 0;
    for (var item in _cart.items) {
      total += item.price * item.quantity;
    }
    return total;
  }
  
  double get totalAmount => totalPrice; // For backward compatibility
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get cartId => _cart.id;

  // Set context for showing messages
  void setContext(BuildContext context) {
    _context = context;
  }

  // Show error message
  void _showMessage(String? message, {bool isError = true}) {
    if (_context != null && _context!.mounted && message != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Refresh cart data from server
  Future<void> refreshCart() async {
    return await fetchCart();
  }
 
  // Fetch cart from API
  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (kDebugMode) {
        print('🛒 Fetching cart from server');
      }
      
      // Use timeout to prevent infinite loading
      final response = await _apiService.get('/api/client/cart')
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Cart fetch timed out');
      });
      
      if (kDebugMode) {
        print('🛒 Cart response: $response');
      }
      
      if (response['code'] == 200 && response['data'] != null) {
        _cart = Cart.fromMap(response['data']);
       
        
        if (kDebugMode) {
          print('✅ Cart fetched successfully');
          print('   Cart ID: ${_cart.id}');
          print('   Items: ${itemCount}'); // Use our recalculated item count
          print('   Total: ${totalPrice}'); // Use our recalculated total price
        }
        
        _error = null;
      } else {
        // If cart fetch failed but we have a previous non-empty cart, keep it
        if (_cart.items.isNotEmpty) {
          if (kDebugMode) {
            print('⚠️ Cart fetch failed but keeping existing cart data');
          }
        } else {
          // Reset to empty cart if we don't have a previous cart
          _cart = Cart.empty();
        }
        
        _error = response['message'] ?? 'Failed to fetch cart';
        if (kDebugMode) {
          print('❌ Error fetching cart: $_error');
        }
      }
    } catch (e) {
      // If we have an error but previous cart exists, keep it
      if (_cart.items.isNotEmpty) {
        if (kDebugMode) {
          print('⚠️ Exception fetching cart but keeping existing cart data: $e');
        }
      }
      
      _error = e.toString();
      if (kDebugMode) {
        print('❌ Exception fetching cart: $e');
      }
    } finally {
      // Always set loading to false to avoid UI freeze
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if the requested quantity is available in stock
  bool isQuantityAvailable(CartItem item, int newQuantity) {
    if (item.availableQuantity == null) return true; // No inventory information, assume available
    return newQuantity <= item.availableQuantity!;
  }
  
  // Show out-of-stock message
  void showOutOfStockMessage(String productTitle) {
    _showMessage(
      'Maximum available stock reached for product: $productTitle', 
      isError: true
    );
  }

  // Update quantity with stock checking
  Future<bool> updateQuantity(String id, int newQuantity, {String? variant}) async {
    if (newQuantity <= 0) {
      return removeItem(id, variant: variant);
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Find item in the cart
      final index = _cart.items.indexWhere((item) => 
        item.id == id && (variant == null || item.variant == variant)
      );
      
      if (index == -1) {
        _error = 'Product not found in cart';
        _isLoading = false;
        notifyListeners();
        _showMessage(_error);
        return false;
      }
      
      final item = _cart.items[index];
      
      // Check if the requested quantity is available
      if (!isQuantityAvailable(item, newQuantity)) {
        _isLoading = false;
        showOutOfStockMessage(item.title);
        notifyListeners();
        return false;
      }
      
      // Lưu lại cart trước khi cập nhật để có thể khôi phục nếu cần
      final previousCart = _cart;
      
      // Tính toán chênh lệch số lượng và giá
      final quantityDifference = newQuantity - item.quantity;
      final priceDifference = item.price * quantityDifference;
      
      // Tạo bản sao của danh sách items để cập nhật
      final updatedItems = [..._cart.items];
      updatedItems[index] = CartItem(
        id: item.id,
        barcode: item.barcode,
        giftCard: item.giftCard,
        grams: item.grams,
        handle: item.handle,
        image: item.image,
        linePrice: item.linePrice + priceDifference,
        linePriceOriginal: item.linePriceOriginal,
        notAllowPromotion: item.notAllowPromotion,
        price: item.price,
        priceOriginal: item.priceOriginal,
        productId: item.productId,
        productTitle: item.productTitle,
        productType: item.productType,
        properties: item.properties,
        quantity: newQuantity,
        requiresShipping: item.requiresShipping,
        sku: item.sku,
        title: item.title,
        url: item.url,
        variantId: item.variantId,
        variantTitle: item.variantTitle,
        vendor: item.vendor,
        variantOptions: item.variantOptions,
        variant: item.variant,
        availableQuantity: item.availableQuantity,
        line: item.line,
      );
      
      // Cập nhật cart với số lượng mới
      _cart = Cart(
        id: _cart.id,
        attributes: _cart.attributes,
        customerId: _cart.customerId,
        itemCount: _cart.itemCount + quantityDifference,
        items: updatedItems,
        locationId: _cart.locationId,
        note: _cart.note,
        requiresShipping: _cart.requiresShipping,
        token: _cart.token,
        totalPrice: _cart.totalPrice + priceDifference,
        totalWeight: _cart.totalWeight,
      );
      
      // Cập nhật UI ngay lập tức
      _isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('🛒 Updating cart item:');
        print('   Item ID: $id');
        print('   New quantity: $newQuantity');
        print('   Line: ${item.line}');
      }
      
      // Continue with API call
      final result = await _apiService.updateCartItem(
        itemId: id,
        quantity: newQuantity,
        line: item.line,
      );
      
      if (result['code'] == 200) {
        // API call successful, we could update from server response but keep our current UI state
        // for smoother experience
        _error = null;
        
        if (kDebugMode) {
          print('✅ Quantity updated successfully');
        }
        
        return true;
      } else {
        // API call failed, revert to previous state
        _cart = previousCart;
        _error = result['message'] ?? 'Failed to update item quantity';
        
        // Notify UI to refresh with old state
        notifyListeners();
        _showMessage(_error);
        
        if (kDebugMode) {
          print('❌ Error updating quantity: $_error');
        }
        
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      _showMessage('Error updating item quantity: $_error');
      
      if (kDebugMode) {
        print('❌ Exception updating quantity: $e');
      }
      
      return false;
    }
  }

  // Add item with stock checking
  Future<bool> addItem(dynamic variantId, String title, double price, String? imageUrl, {
    int quantity = 1, 
    String? variant,
    Map<String, dynamic>? properties,
    int? availableQuantity,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // First check if the item is already in the cart
      final existingItem = _cart.items.firstWhere(
        (item) => item.variantId.toString() == variantId.toString(),
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
          variantId: 0
        ),
      );
      
      if (existingItem.id.isNotEmpty) {
        // If item already in cart, update quantity instead
        final newQuantity = existingItem.quantity + quantity;
        
        // Check if the requested quantity is available
        if (existingItem.availableQuantity != null && newQuantity > existingItem.availableQuantity!) {
          _isLoading = false;
          showOutOfStockMessage(existingItem.title);
          notifyListeners();
          return false;
        }
        
        return updateQuantity(existingItem.id, newQuantity);
      }
      
      // New item, add to cart
      final result = await _apiService.addToCart(
        variantId: variantId,
        quantity: quantity,
        properties: properties,
      );
      
      if (result['code'] == 200 && result['data'] != null) {
        // Update the local cart
        _cart = Cart.fromMap(result['data']);
        _error = null;
        
        _isLoading = false;
        notifyListeners();
        
        if (kDebugMode) {
          print('✅ Item added to cart successfully');
        }
        
        return true;
      } else {
        _error = result['message'] ?? 'Failed to add item to cart';
        _isLoading = false;
        notifyListeners();
        _showMessage(_error);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      _showMessage('Error adding item to cart: $_error');
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeItem(String id, {String? variant}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
    // Save old items for finding the item index
    final oldItems = [..._cart.items];
    final removedItemIndex = oldItems.indexWhere(
      (item) => item.id == id && (variant == null || item.variant == variant)
    );
    
    if (removedItemIndex < 0) {
      if (kDebugMode) {
        print('❌ Item not found in cart for removal: $id');
      }
        _isLoading = false;
        notifyListeners();
      return false;
    }
    
    // Get the item to be removed
    CartItem removedItem = oldItems[removedItemIndex];
      
      // Cập nhật UI trước khi gửi API request (optimistic update)
      List<CartItem> newItems = [...oldItems];
      newItems.removeAt(removedItemIndex);
    
      // Lưu cart cũ để phục hồi nếu cần
      final previousCart = _cart;
    
      // Cập nhật cart trước khi gửi API request để UI cảm thấy mượt mà
    _cart = Cart(
      id: _cart.id,
      attributes: _cart.attributes,
      customerId: _cart.customerId,
      itemCount: _cart.itemCount - removedItem.quantity,
      items: newItems,
      locationId: _cart.locationId,
      note: _cart.note,
      requiresShipping: _cart.requiresShipping,
      token: _cart.token,
      totalPrice: _cart.totalPrice - (removedItem.price * removedItem.quantity),
      totalWeight: _cart.totalWeight,
    );
      
      // Thông báo UI cập nhật ngay lập tức
      _isLoading = false;
      notifyListeners();
    
      if (kDebugMode) {
        print('🛒 Removing item from cart:');
        print('   Item ID: $id');
        print('   Line: ${removedItem.line}');
      }
      
      // Gửi API request để xóa sản phẩm khỏi giỏ hàng trên server
      final response = await _apiService.post('/api/client/cart/change', {
        'line': removedItem.line, // Use the line number from the item
        'quantity': 0, // Setting quantity to 0 removes the item
      });

      if (response['code'] == 200) {
        // Xóa thành công, không cần làm gì thêm vì đã cập nhật UI
            _error = null;
            
            if (kDebugMode) {
          print('✅ Item removed successfully');
            }
        
          return true;
      } else {
        // Nếu API báo lỗi, phục hồi lại trạng thái cũ
        _cart = previousCart;
        _error = response['message'] ?? 'Failed to remove item from cart';
        
        if (kDebugMode) {
          print('❌ Error removing from cart: $_error');
        }
        
        // Thông báo UI cập nhật lại
        notifyListeners();
        _showMessage(_error);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      
      if (kDebugMode) {
        print('❌ Error removing from cart: $e');
      }
      
      _isLoading = false;
      notifyListeners();
      _showMessage('Unable to remove product. Please try again later.');
      
      return false;
    }
  }

  // Clear entire cart
  Future<bool> clear() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (kDebugMode) {
        print('🛒 Clearing cart');
      }
      
      final response = await _apiService.delete('/api/client/cart/clear');
      
      if (response['code'] == 200) {
        _cart = Cart.empty();
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to clear cart';
        
        if (kDebugMode) {
          print('❌ Error clearing cart: $_error');
        }
        
        // Try to fetch cart to ensure data is accurate
        await refreshCart();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ Error clearing cart: $e');
      }
      
      // Show error message
      // _showMessage('Unable to clear cart. Please try again later.');
      
      // Try to fetch cart to ensure data is accurate
      await refreshCart();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
