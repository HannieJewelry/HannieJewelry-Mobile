import 'package:flutter/foundation.dart';
import '../../../features/checkout/models/order_model.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import 'dart:convert'; // Added for json.encode

class OrderService extends ChangeNotifier {
  final AuthService _authService;
  final ApiService _apiService;
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  OrderService(this._authService, this._apiService);

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  // Get all orders (GET /api/client/orders/me)
  Future<void> fetchOrders() async {
    if (!_authService.isAuthenticated) {
      print('❌ Cannot fetch orders: User is not authenticated');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      print('🔍 Fetching orders for user: ${user?.id} (${user?.name})');
      print('🔑 Authentication status: ${_authService.isAuthenticated ? 'Authenticated' : 'Not authenticated'}');
      
      // Kiểm tra và đảm bảo token được đặt đúng cách
      if (_apiService.headers.containsKey('Authorization')) {
        print('✅ Authorization header is set: ${_apiService.headers['Authorization']}');
        
        // Kiểm tra xem token có đúng định dạng Bearer không
        final response = await _apiService.get('/api/client/orders/me');
        
        if (response != null && response['code'] == 200) {
          // Xử lý response thành công
          if (response['data'] != null && response['data'] is List) {
            final List<dynamic> ordersData = response['data'];
            print('📋 Found ${ordersData.length} orders');
            
            _orders = ordersData.map((order) => OrderModel.fromMap(order)).toList();
            print('✅ Successfully parsed ${_orders.length} orders');
          } else {
            print('ℹ️ Found no orders or empty orders array');
            _orders = [];
          }
        } else if (response?['code'] == 401 || 
            (response?['message'] != null && 
             response!['message'].toString().toLowerCase().contains('unauthorized'))) {
          print('🔒 Authentication error detected. Attempting to refresh authentication...');
          // Thử xác thực lại hoặc refresh token
          await _refreshAuthentication();
          // Thử lại request sau khi refresh token
          await _retryFetchOrders();
        } else {
          // Fallback với dữ liệu mẫu nếu API fails
          _initializeSampleOrders();
        }
      }
    } catch (e) {
      print('❌ Exception when getting order list: $e');
      
      // Kiểm tra nếu lỗi là do xác thực
      if (e.toString().toLowerCase().contains('unauthorized') || 
          e.toString().toLowerCase().contains('401')) {
        print('🔒 Authentication error detected. Attempting to refresh authentication...');
        // Thử xác thực lại hoặc refresh token
        await _refreshAuthentication();
        // Thử lại request sau khi refresh token
        await _retryFetchOrders();
      } else {
        // Fallback với dữ liệu mẫu nếu API fails
        _initializeSampleOrders();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Thử lại việc lấy danh sách đơn hàng sau khi refresh token
  Future<void> _retryFetchOrders() async {
    try {
      print('🔄 Retrying order fetch after authentication refresh');
      
      final response = await _apiService.get('/api/client/orders/me');
      
      if (response != null && response['code'] == 200) {
        // Xử lý cấu trúc mới: data là array trực tiếp
        if (response['data'] != null && response['data'] is List) {
          
          final List<dynamic> ordersData = response['data'];
          print('📋 Retry found ${ordersData.length} orders');
          
          _orders = ordersData.map((order) => OrderModel.fromMap(order)).toList();
          print('✅ Retry successfully parsed ${_orders.length} orders');
        } else {
          print('ℹ️ Retry found no orders or empty orders array');
          _orders = [];
        }
      } else {
        print('❌ Retry error fetching orders: ${response?['message'] ?? 'Unknown error'}');
        // Fallback với dữ liệu mẫu nếu API vẫn fails
        _initializeSampleOrders();
      }
    } catch (e) {
      print('❌ Exception in retry fetch orders: $e');
      // Fallback với dữ liệu mẫu nếu API vẫn fails
      _initializeSampleOrders();
    }
  }

  Future<bool> cancelOrder(String orderId, String reason, String note) async {
    try {
      print('🚫 Cancelling order: $orderId');
      print('   Reason: $reason');
      print('   Note: $note');
      
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final response = await _apiService.put(
        '/api/client/orders/me/$orderId/cancel',
        {
          'reason': reason,
          'note': note,
        },
      );
      
      if (response != null && response['code'] == 200) {
        print('✅ Order cancelled successfully');
        
        // Update the local order status instead of fetching all orders
        // This prevents FutureBuilder from rebuilding and showing loading spinner
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1 && response['data'] != null) {
          try {
            _orders[index] = OrderModel.fromMap(response['data']);
            notifyListeners();
            print('✅ Updated local order status to cancelled');
          } catch (e) {
            print('⚠️ Error updating local order: $e');
            // If local update fails, we can still return true since API succeeded
          }
        }
        
        return true;
      } else {
        print('❌ Failed to cancel order: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('❌ Error cancelling order: $e');
      return false;
    }
  }
  
  // Helper method to refresh authentication if needed
  Future<void> _refreshAuthentication() async {
    try {
      // Try to refresh the user's session
      await _authService.initialize();
      
      // Check if we're authenticated after refresh
      if (_authService.isAuthenticated) {
        print('✅ Authentication refreshed successfully');
      } else {
        print('❌ Failed to refresh authentication');
        // We could show a login prompt here
      }
    } catch (e) {
      print('❌ Error refreshing authentication: $e');
    }
  }

  // Initialize sample data (only used when API fails)
  void _initializeSampleOrders() {
    _orders = [
      OrderModel(
        id: 'ORD123456',
        items: [
          OrderItem(
            productId: 'P001',
            name: '18K Gold Bracelet',
            imageUrl: 'assets/images/placeholder.png',
            price: 2500000,
            quantity: 1,
          ),
        ],
        totalAmount: 2500000,
        shippingFee: 30000,
        deliveryMethod: DeliveryMethod.delivery,
        paymentMethod: PaymentMethod.cod,
        recipientName: 'John Doe',
        recipientPhone: '0901234567',
        recipientAddress: '123 ABC Street, District 1, HCMC',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Add other sample orders if needed
    ];

    notifyListeners();
  }

  // Create new order with Map data (POST /api/orders)
  Future<Map<String, dynamic>?> createOrder(Map<String, dynamic> orderData) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🛒 Creating order with data: $orderData');
      
      final response = await _apiService.post('/api/orders', orderData);
      
      if (response != null && response['code'] == 200 && response['data'] != null) {
        print('✅ Order created successfully');
        
        // Try to convert to OrderModel and add to list if authenticated
        if (_authService.isAuthenticated) {
          try {
        final newOrder = OrderModel.fromMap(response['data']);
            _orders.insert(0, newOrder);
        notifyListeners();
          } catch (e) {
            print('⚠️ Error converting response to OrderModel: $e');
          }
        }
        
        return response['data'];
      } else {
        print('❌ Error creating order: ${response?['message'] ?? 'Unknown error'}');
        print('❌ Response: $response');
        return null;
      }
    } catch (e) {
      print('❌ Error when creating order: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get order details by ID (GET /api/orders/{id})
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      print('🔍 Fetching order details for ID: $orderId');
      
      if (!_authService.isAuthenticated) {
        print('❌ Cannot fetch order: User is not authenticated');
        return null;
      }
      
      // Kiểm tra và đảm bảo token được đặt đúng cách
      if (!_apiService.headers.containsKey('Authorization') || 
          !(_apiService.headers['Authorization'] ?? '').startsWith('Bearer ')) {
        print('⚠️ Authorization header is missing or invalid - refreshing authentication');
        await _refreshAuthentication();
      }
      
      // First check if we already have this order in memory
      try {
        final cachedOrder = _orders.firstWhere((order) => order.id == orderId);
        print('✅ Found order in local cache: ${cachedOrder.id}');
        return cachedOrder;
      } catch (e) {
        // Not found in local cache, continue with API call
        print('ℹ️ Order not found in local cache, fetching from API');
      }
      
      // Use the correct API endpoint
      final response = await _apiService.get('/api/orders/$orderId');
      print('📦 Order API response: $response');
      
      if (response != null && response['code'] == 200) {
        print('✅ Successfully fetched order from API');
        
        // Handle the nested structure if present
        if (response['data'] != null) {
          if (response['data']['result'] != null) {
            return OrderModel.fromMap(response['data']['result']);
          } else {
            return OrderModel.fromMap(response['data']);
          }
        } else {
          print('❌ No order data found in response');
          return null;
        }
      } else {
        print('❌ Error getting order: ${response?['message'] ?? 'Unknown error'}');
        
        // Kiểm tra nếu lỗi là do xác thực
        if (response?['code'] == 401 || 
            (response?['message'] != null && 
             response!['message'].toString().toLowerCase().contains('unauthorized'))) {
          print('🔒 Authentication error detected. Attempting to refresh authentication...');
          await _refreshAuthentication();
          
          // Thử lại request sau khi refresh token
          return _retryGetOrderById(orderId);
        }
        
        return null;
      }
    } catch (e) {
      print('❌ Error when getting order details: $e');
      
      // Kiểm tra nếu lỗi là do xác thực
      if (e.toString().toLowerCase().contains('unauthorized') || 
          e.toString().toLowerCase().contains('401')) {
        print('🔒 Authentication error detected. Attempting to refresh authentication...');
        await _refreshAuthentication();
        
        // Thử lại request sau khi refresh token
        return _retryGetOrderById(orderId);
      }
      
      // Fallback to search in local data if API fails
      try {
        final localOrder = _orders.firstWhere((order) => order.id == orderId);
        print('✅ Found order in local data after API error');
        return localOrder;
      } catch (e) {
        print('❌ Order not found in local data either');
        return null;
      }
    }
  }
  
  // Thử lại việc lấy chi tiết đơn hàng sau khi refresh token
  Future<OrderModel?> _retryGetOrderById(String orderId) async {
    try {
      print('🔄 Retrying get order details after authentication refresh');
      
      final response = await _apiService.get('/api/orders/$orderId');
      
      if (response != null && response['code'] == 200 && response['data'] != null) {
        if (response['data']['result'] != null) {
          return OrderModel.fromMap(response['data']['result']);
        } else {
          return OrderModel.fromMap(response['data']);
        }
      }
    } catch (e) {
      print('❌ Exception in retry get order details: $e');
    }
    
    // Fallback to search in local data if retry API call fails
    try {
      final localOrder = _orders.firstWhere((order) => order.id == orderId);
      print('✅ Found order in local data after retry API error');
      return localOrder;
    } catch (e) {
      print('❌ Order not found in local data after retry');
      return null;
    }
  }

  // Update order (PUT /api/orders/{id})
  Future<bool> updateOrder(String orderId, Map<String, dynamic> updateData) async {
    if (!_authService.isAuthenticated) return false;

    try {
      final response = await _apiService.put('/api/orders/$orderId', updateData);
      if (response != null && response['success'] == true) {
        // Update local order list
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1 && response['data'] != null) {
          _orders[index] = OrderModel.fromMap(response['data']);
          notifyListeners();
        }
        return true;
      } else {
        print('❌ Error updating order: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('❌ Error when updating order: $e');
      return false;
    }
  }

  // Delete order (DELETE /api/orders/{id})
  Future<bool> deleteOrder(String orderId) async {
    if (!_authService.isAuthenticated) return false;

    try {
      final response = await _apiService.delete('/api/orders/$orderId');
      if (response != null && response['success'] == true) {
        // Remove from local list
        _orders.removeWhere((order) => order.id == orderId);
        notifyListeners();
        return true;
      } else {
        print('❌ Error deleting order: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('❌ Error when deleting order: $e');
      return false;
    }
  }

  // Confirm order (POST /api/orders/{id}/confirm)
  Future<bool> confirmOrder(String orderId) async {
    if (!_authService.isAuthenticated) return false;

    try {
      final response = await _apiService.post('/api/orders/$orderId/confirm', {});
      if (response != null && response['success'] == true) {
        // Update local order status
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1 && response['data'] != null) {
          _orders[index] = OrderModel.fromMap(response['data']);
          notifyListeners();
        }
        return true;
      } else {
        print('❌ Error confirming order: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('❌ Error when confirming order: $e');
      return false;
    }
  }

  // Close order (POST /api/orders/{id}/close)
  Future<bool> closeOrder(String orderId) async {
    if (!_authService.isAuthenticated) return false;

    try {
      final response = await _apiService.post('/api/orders/$orderId/close', {});
      if (response != null && response['success'] == true) {
        // Update local order status
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1 && response['data'] != null) {
          _orders[index] = OrderModel.fromMap(response['data']);
          notifyListeners();
        }
        return true;
      } else {
        print('❌ Error closing order: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('❌ Error when closing order: $e');
      return false;
    }
  }

  // Reopen order (POST /api/orders/{id}/reopen)
  Future<bool> reopenOrder(String orderId) async {
    if (!_authService.isAuthenticated) return false;

    try {
      final response = await _apiService.post('/api/orders/$orderId/reopen', {});
      if (response != null && response['success'] == true) {
        // Update local order status
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1 && response['data'] != null) {
          _orders[index] = OrderModel.fromMap(response['data']);
          notifyListeners();
        }
        return true;
      } else {
        print('❌ Error reopening order: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('❌ Error when reopening order: $e');
      return false;
    }
  }

  // Add order tags (POST /api/orders/{id}/tags)
  Future<bool> addOrderTags(String orderId, List<String> tags) async {
    if (!_authService.isAuthenticated) return false;

    try {
      final response = await _apiService.post('/api/orders/$orderId/tags', {'tags': tags});
      if (response != null && response['success'] == true) {
        // Update local order
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1 && response['data'] != null) {
          _orders[index] = OrderModel.fromMap(response['data']);
          notifyListeners();
        }
        return true;
      } else {
        print('❌ Error adding order tags: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('❌ Error when adding order tags: $e');
      return false;
    }
  }

  // Delete order tags (DELETE /api/orders/{id}/tags)
  Future<bool> deleteOrderTags(String orderId, List<String> tags) async {
    if (!_authService.isAuthenticated) return false;

    try {
      final response = await _apiService.delete('/api/orders/$orderId/tags');
      if (response != null && response['success'] == true) {
        // Update local order
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1 && response['data'] != null) {
          _orders[index] = OrderModel.fromMap(response['data']);
          notifyListeners();
        }
        return true;
      } else {
        print('❌ Error deleting order tags: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('❌ Error when deleting order tags: $e');
      return false;
    }
  }

  // Legacy method for backward compatibility
  Future<bool> addOrder(OrderModel order) async {
    final result = await createOrder(order.toMap());
    return result != null;
  }
  
  // Get order by checkout order ID
  Future<Map<String, dynamic>?> getOrderByCheckoutId(String checkoutOrderId) async {
    try {
      if (kDebugMode) {
        print('🔍 OrderService: Fetching order details for checkout order ID: $checkoutOrderId');
      }
      
      // Gọi API để lấy thông tin đơn hàng từ ID đơn hàng checkout
      final response = await _apiService.get('/api/orders/bp/view/$checkoutOrderId');
      
      if (kDebugMode) {
        print('📦 OrderService: Order response: $response');
      }
      
      if (response != null && response['code'] == 200 && response['data'] != null) {
        final orderData = response['data'];
        print('✅ OrderService: Successfully fetched order from checkout ID');
        return orderData;
      } else {
        print('❌ OrderService: Error getting order from checkout ID: ${response?['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      print('❌ OrderService: Exception when getting order from checkout ID: $e');
      return null;
    }
  }

  // Process order with the new API format
  Future<Map<String, dynamic>?> processOrder({
    required String email,
    required List<Map<String, dynamic>> lineItems,
    required Map<String, dynamic> shippingAddress,
    Map<String, dynamic>? billingAddress,
    List<Map<String, dynamic>>? discountCodes,
    List<Map<String, dynamic>>? shippingLines,
    String? gateway,
    String? note,
    String? tags,
    String? landingSite,
    String? landingSiteRef,
    String? source,
    String? sourceName,
    List<Map<String, dynamic>>? noteAttributes,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? utmTerm,
    String? utmContent,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Format request according to the API requirements
      final Map<String, dynamic> requestBody = {
        'order': {
          'email': email,
          'line_items': lineItems,
          'shipping_address': shippingAddress,
        }
      };
      
      // Add optional fields only if they are provided
      if (billingAddress != null) {
        requestBody['order']['billing_address'] = billingAddress;
      }
      
      if (discountCodes != null) {
        requestBody['order']['discount_codes'] = discountCodes;
      }
      
      if (shippingLines != null) {
        requestBody['order']['shipping_lines'] = shippingLines;
      }
      
      if (gateway != null) {
        requestBody['order']['gateway'] = gateway;
      }
      
      if (note != null) {
        requestBody['order']['note'] = note;
      }
      
      if (tags != null) {
        requestBody['order']['tags'] = tags;
      }
      
      if (landingSite != null) {
        requestBody['order']['landing_site'] = landingSite;
      }
      
      if (landingSiteRef != null) {
        requestBody['order']['landing_site_ref'] = landingSiteRef;
      }
      
      if (source != null) {
        requestBody['order']['source'] = source;
      }
      
      if (sourceName != null) {
        requestBody['order']['source_name'] = sourceName;
      }
      
      if (noteAttributes != null) {
        requestBody['order']['note_attributes'] = noteAttributes;
      }
      
      if (utmSource != null) {
        requestBody['order']['utm_source'] = utmSource;
      }
      
      if (utmMedium != null) {
        requestBody['order']['utm_medium'] = utmMedium;
      }
      
      if (utmCampaign != null) {
        requestBody['order']['utm_campaign'] = utmCampaign;
      }
      
      if (utmTerm != null) {
        requestBody['order']['utm_term'] = utmTerm;
      }
      
      if (utmContent != null) {
        requestBody['order']['utm_content'] = utmContent;
      }
      
      // Make the API call
      print('🛒 Processing order with API: ${json.encode(requestBody)}');
      final response = await _apiService.post('/api/orders', requestBody);
      
      if (response != null) {
        print('📦 Order API response: $response');
        
        if (response['code'] == 202) {
          print('✅ Order successfully submitted. Order ID: ${response['data']?['order_id']}');
          return response['data'];
        } else {
          print('❌ Error processing order: ${response['message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        print('❌ Null response when processing order');
        return null;
      }
    } catch (e) {
      print('❌ Exception when processing order: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get order status history (GET /api/orders/{id}/status-history)
  Future<List<Map<String, dynamic>>> getOrderStatusHistory(String orderId) async {
    if (!_authService.isAuthenticated) return [];

    try {
      print('🔍 Fetching order status history for ID: $orderId');
      
      // Kiểm tra và đảm bảo token được đặt đúng cách
      if (!_apiService.headers.containsKey('Authorization') || 
          !(_apiService.headers['Authorization'] ?? '').startsWith('Bearer ')) {
        print('⚠️ Authorization header is missing or invalid - refreshing authentication');
        await _refreshAuthentication();
      }
      
      final response = await _apiService.get('/api/orders/$orderId/status-history');
      
      if (response != null && response['code'] == 200 && response['data'] != null) {
        // Xử lý cấu trúc đúng: data -> result
        if (response['data']['result'] != null) {
          if (response['data']['result'] is List) {
            final List<dynamic> historyData = response['data']['result'];
            print('✅ Successfully fetched order status history: ${historyData.length} entries');
            return List<Map<String, dynamic>>.from(historyData);
          } else if (response['data']['result']['content'] != null && 
                    response['data']['result']['content'] is List) {
            // Một số API có thể trả về cấu trúc phân trang
            final List<dynamic> historyData = response['data']['result']['content'];
            print('✅ Successfully fetched paginated order status history: ${historyData.length} entries');
            return List<Map<String, dynamic>>.from(historyData);
          }
        } else if (response['data'] is List) {
          final List<dynamic> historyData = response['data'];
          print('✅ Successfully fetched order status history (direct list): ${historyData.length} entries');
          return List<Map<String, dynamic>>.from(historyData);
        }
      }
      
      // Xử lý trường hợp response không đúng định dạng hoặc không có dữ liệu
      print('⚠️ Order status history response format unexpected or empty: $response');
      print('⚠️ Using sample order status history data');
      return _getSampleOrderStatusHistory(orderId);
    } catch (e) {
      print('❌ Error when getting order status history: $e');
      
      // Nếu lỗi là do xác thực, thử refresh token và gọi lại
      if (e.toString().toLowerCase().contains('unauthorized') || 
          e.toString().toLowerCase().contains('401')) {
        print('🔒 Authentication error detected. Attempting to refresh authentication...');
        await _refreshAuthentication();
        
        // Thử lại request sau khi refresh token
        try {
          final retryResponse = await _apiService.get('/api/orders/$orderId/status-history');
          
          if (retryResponse != null && retryResponse['code'] == 200 && retryResponse['data'] != null) {
            if (retryResponse['data']['result'] != null && retryResponse['data']['result'] is List) {
              final List<dynamic> historyData = retryResponse['data']['result'];
              return List<Map<String, dynamic>>.from(historyData);
            } else if (retryResponse['data'] is List) {
              final List<dynamic> historyData = retryResponse['data'];
              return List<Map<String, dynamic>>.from(historyData);
            }
          }
        } catch (retryError) {
          print('❌ Retry error: $retryError');
        }
      }
      
      return _getSampleOrderStatusHistory(orderId);
    }
  }
  
  // Track order using cart token (GET /api/client/orders/tracking?token={cartToken})
  Future<Map<String, dynamic>?> trackOrder(String cartToken) async {
    try {
      print('🔍 Tracking order with cart token: $cartToken');
      
      final response = await _apiService.get('/api/client/orders/tracking?token=$cartToken');
      
      print('📦 Order tracking API response: $response');
      
      if (response != null && response['code'] == 200) {
        print('✅ Successfully tracked order with cart token');
        
        // Handle the nested structure and extract the first order if it's a list
        if (response['data'] != null) {
          if (response['data'] is List && (response['data'] as List).isNotEmpty) {
            // API returns an array of orders, we take the first one
            final orderData = (response['data'] as List).first;
            
            // Extract additional fields that might not be in the regular OrderModel
            final Map<String, dynamic> enhancedOrderData = Map.from(orderData);
            
            // Add enhanced fields for display
            enhancedOrderData['enhanced'] = true;
            
            // Map the fields to match OrderModel expectations
            if (orderData['order_code'] != null) {
              enhancedOrderData['id'] = orderData['order_code'];
            }
            
            if (orderData['order_number'] != null) {
              enhancedOrderData['order_number'] = orderData['order_number'];
            }
            
            if (orderData['total_price'] != null) {
              enhancedOrderData['total_amount'] = orderData['total_price'];
            }
            
            if (orderData['line_items'] != null) {
              enhancedOrderData['items'] = orderData['line_items'];
            }
            
            if (orderData['name'] != null) {
              enhancedOrderData['recipient_name'] = orderData['name'];
            }
            
            if (orderData['email'] != null) {
              enhancedOrderData['customer_email'] = orderData['email'];
            }
            
            if (orderData['financial_status'] != null) {
              enhancedOrderData['financial_status'] = orderData['financial_status'];
            }
            
            if (orderData['fulfillment_status'] != null) {
              enhancedOrderData['fulfillment_status'] = orderData['fulfillment_status'];
            }
            
            if (orderData['order_processing_status'] != null) {
              enhancedOrderData['order_processing_status'] = orderData['order_processing_status'];
            }
            
            return enhancedOrderData;
          } else if (response['data']['result'] != null) {
            return response['data']['result'] as Map<String, dynamic>;
          } else {
            return response['data'] as Map<String, dynamic>;
          }
        } else {
          print('❌ No tracking data found in response');
          return null;
        }
      } else {
        print('❌ Error tracking order: ${response?['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      print('❌ Error when tracking order: $e');
      return null;
    }
  }
  
  // Update order status (POST /api/orders/{id}/update-status)
  Future<bool> updateOrderStatus(String orderId, String status, {String? note}) async {
    if (!_authService.isAuthenticated) return false;

    try {
      final data = {
        'status': status,
        if (note != null) 'note': note,
      };
      
      final response = await _apiService.post('/api/orders/$orderId/update-status', data);
      
      if (response != null && (response['code'] == 200 || response['success'] == true)) {
        // Update local order status if data is returned
        if (response['data'] != null) {
          final index = _orders.indexWhere((order) => order.id == orderId);
          if (index != -1) {
            if (response['data']['result'] != null) {
              _orders[index] = OrderModel.fromMap(response['data']['result']);
            } else {
              _orders[index] = OrderModel.fromMap(response['data']);
            }
            notifyListeners();
          }
        }
        return true;
      } else {
        print('❌ Error updating order status: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('❌ Error when updating order status: $e');
      return false;
    }
  }
  
  // Sample order status history data for fallback
  List<Map<String, dynamic>> _getSampleOrderStatusHistory(String orderId) {
    final now = DateTime.now();
    
    return [
      {
        'status': 'CREATED',
        'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
        'note': 'Order placed successfully',
        'userId': 'system',
      },
      {
        'status': 'CONFIRMED',
        'timestamp': now.subtract(const Duration(days: 1, hours: 12)).toIso8601String(),
        'note': 'Order confirmed by admin',
        'userId': 'admin',
      },
      {
        'status': 'PROCESSING',
        'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        'note': 'Order is being processed',
        'userId': 'admin',
      },
      {
        'status': 'SHIPPED',
        'timestamp': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'note': 'Order has been shipped',
        'userId': 'admin',
      },
      {
        'status': 'DELIVERED',
        'timestamp': now.toIso8601String(),
        'note': 'Order has been delivered',
        'userId': 'system',
      },
    ];
  }
}