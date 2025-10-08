import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../../profile/models/address_model.dart';
import '../models/order_model.dart';

class CheckoutService extends ChangeNotifier {
  final ApiService _apiService;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _checkoutData;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get checkoutData => _checkoutData;

  // Constructor
  CheckoutService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  // Get checkout information using JWT authentication
  Future<Map<String, dynamic>?> getCheckoutInfo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (kDebugMode) {
        print('🛒 Fetching checkout info with JWT authentication');
      }
      
      final response = await _apiService.get('/api/client/checkout');
      
      if (kDebugMode) {
        print('🛒 Checkout response: $response');
        print('🛒 Full response data: ${response['data']}');
        print('🛒 Response code: ${response['code']}');
        print('🛒 Response message: ${response['message']}');
      }
      
      if (response['code'] == 200 && response['data'] != null) {
        _checkoutData = response['data'];
        _error = null;
        
        if (kDebugMode) {
          print('✅ Checkout info fetched successfully');
          print('   Total: ${getTotalPrice(_checkoutData)}');
          print('   Items: ${getLineItems(_checkoutData).length}');
          print('   Shipping methods: ${getShippingMethods(_checkoutData).length}');
          print('   Payment methods: ${getPaymentMethods(_checkoutData).length}');
        }
        
        notifyListeners();
        return _checkoutData;
      } else {
        _error = response['message'] ?? 'Failed to fetch checkout information';
        if (kDebugMode) {
          print('❌ Error fetching checkout info: $_error');
        }
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ Exception fetching checkout info: $e');
      }
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Convert checkout data to OrderModel
  OrderModel? convertToOrderModel(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    try {
      final lineItems = getLineItems(data);
      final List<OrderItem> orderItems = lineItems.map((item) => 
        OrderItem(
          productId: item['product_id'] ?? item['id'] ?? '',
          name: item['product_title'] ?? item['title'] ?? 'Unknown Product',
          imageUrl: item['image_url'] ?? item['image'] ?? '',
          price: _toDouble(item['price'] ?? 0),
          quantity: item['quantity'] ?? 1,
        )
      ).toList();
      
      return OrderModel(
        id: data['id'] ?? '',
        items: orderItems,
        totalAmount: getTotalPrice(data),
        shippingFee: getShippingCost(data),
        deliveryMethod: DeliveryMethod.delivery, // Default
        paymentMethod: PaymentMethod.cod, // Default
        recipientName: data['full_name'] ?? '',
        recipientPhone: data['phone'] ?? '',
        recipientAddress: data['shipping_address'] ?? '',
        note: data['note']?.toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error converting to OrderModel: $e');
      }
      return null;
    }
  }
  
  // Kiểm tra xem checkout có dữ liệu không
  bool hasCheckoutData() {
    return _checkoutData != null && _checkoutData!.isNotEmpty;
  }
  
  // Lấy thông tin khách hàng từ checkout
  Map<String, dynamic>? getCustomerInfo(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    try {
      return {
        'full_name': data['full_name'],
        'email': data['email'],
        'phone': data['phone'],
        'phone_country_code': data['phone_country_code'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing customer info: $e');
      }
      return null;
    }
  }
  
  // Parse address information from checkout data
  Address? parseShippingAddress(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    try {
      // Kiểm tra xem có địa chỉ giao hàng trong dữ liệu checkout không
      if (data['shipping_address'] == null && 
          data['shipping_province_id'] == null &&
          data['shipping_district_id'] == null) {
        return null;
      }
      
      // Tạo dữ liệu địa chỉ từ các trường riêng lẻ
      final String name = data['full_name'] ?? '';
      final String phone = data['phone'] ?? '';
      
      // Xây dựng địa chỉ từ các thành phần
      final String address1 = data['shipping_address'] ?? '';
      final String city = data['shipping_city'] ?? '';
      final String zip = data['shipping_zip_code'] ?? '';
      final String company = data['shipping_company'] ?? '';
      
      // Tạo firstName và lastName từ fullName nếu có
      String firstName = '';
      String lastName = '';
      if (name.isNotEmpty) {
        final nameParts = name.split(' ');
        if (nameParts.length > 1) {
          firstName = nameParts.first;
          lastName = nameParts.skip(1).join(' ');
        } else {
          firstName = name;
          lastName = '';
        }
      }
      
      return Address(
        id: '', // ID không có trong response
        firstName: firstName,
        lastName: lastName,
        name: name,
        address1: address1,
        address2: '',
        city: city,
        company: company,
        countryCode: 'VN', // Mặc định là Việt Nam
        districtCode: data['shipping_district_id']?.toString(),
        provinceCode: data['shipping_province_id']?.toString(),
        wardCode: data['shipping_ward_id']?.toString(),
        phone: phone,
        zip: zip,
        isDefault: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing shipping address: $e');
      }
      return null;
    }
  }
  
  // Get shipping methods available for the checkout
  List<Map<String, dynamic>> getShippingMethods(Map<String, dynamic>? data) {
    if (data == null || !data.containsKey('shipping_methods')) {
      return [];
    }
    
    try {
      // API trả về danh sách shipping methods là một mảng các object
      return List<Map<String, dynamic>>.from(data['shipping_methods'] ?? []);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing shipping methods: $e');
      }
      return [];
    }
  }
  
  // Get payment methods available for the checkout
  List<Map<String, dynamic>> getPaymentMethods(Map<String, dynamic>? data) {
    if (data == null || !data.containsKey('payment_methods')) {
      return [];
    }
    
    try {
      // API trả về danh sách payment methods là một mảng các object
      return List<Map<String, dynamic>>.from(data['payment_methods'] ?? []);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing payment methods: $e');
      }
      return [];
    }
  }
  
  // Get subtotal amount
  double getSubtotal(Map<String, dynamic>? data) {
    if (data == null) return 0.0;
    
    try {
      // Trong response mới, trường này là sub_total_before_tax
      return _toDouble(data['sub_total_before_tax'] ?? 0.0);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting subtotal: $e');
      }
      return 0.0;
    }
  }
  
  // Get shipping cost
  double getShippingCost(Map<String, dynamic>? data) {
    if (data == null) return 0.0;
    
    try {
      // Trong response mới, trường này là shipping
      return _toDouble(data['shipping'] ?? 0.0);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting shipping cost: $e');
      }
      return 0.0;
    }
  }
  
  // Get total price
  double getTotalPrice(Map<String, dynamic>? data) {
    if (data == null) return 0.0;
    
    try {
      // Trong response mới, trường này là total
      return _toDouble(data['total'] ?? 0.0);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting total price: $e');
      }
      return 0.0;
    }
  }
  
  // Get tax amount
  double getTaxAmount(Map<String, dynamic>? data) {
    if (data == null) return 0.0;
    
    try {
      // Trong response mới, có thể tính bằng cách cộng các loại thuế
      final double includedTax = _toDouble(data['total_tax_included'] ?? 0.0);
      final double notIncludedTax = _toDouble(data['total_tax_not_included'] ?? 0.0);
      return includedTax + notIncludedTax;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting tax amount: $e');
      }
      return 0.0;
    }
  }
  
  // Get discount amount
  double getDiscountAmount(Map<String, dynamic>? data) {
    if (data == null) return 0.0;
    
    try {
      // Trong response mới, trường này là discount
      return _toDouble(data['discount'] ?? 0.0);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting discount amount: $e');
      }
      return 0.0;
    }
  }
  
  // Get line items (products)
  List<Map<String, dynamic>> getLineItems(Map<String, dynamic>? data) {
    if (data == null || !data.containsKey('line_items')) {
      return [];
    }
    
    try {
      // API trả về danh sách line_items là một mảng các object
      return List<Map<String, dynamic>>.from(data['line_items'] ?? []);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing line items: $e');
      }
      return [];
    }
  }
  
  // Lấy tổng số lượng sản phẩm trong giỏ hàng
  int getTotalQuantity(Map<String, dynamic>? data) {
    if (data == null) return 0;
    
    try {
      final lineItems = getLineItems(data);
      int totalQuantity = 0;
      for (var item in lineItems) {
        totalQuantity += (item['quantity'] as int? ?? 0);
      }
      return totalQuantity;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error calculating total quantity: $e');
      }
      return 0;
    }
  }
  
  // Lấy thông tin về ghi chú đơn hàng
  String getOrderNote(Map<String, dynamic>? data) {
    if (data == null) return '';
    
    try {
      return data['note']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }
  
  // Get order attributes
  Map<String, dynamic> getOrderAttributes(Map<String, dynamic>? data) {
    if (data == null || !data.containsKey('attributes')) {
      return {};
    }
    
    try {
      return Map<String, dynamic>.from(data['attributes'] ?? {});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing order attributes: $e');
      }
      return {};
    }
  }
  
  // Update checkout information
  Future<Map<String, dynamic>?> updateCheckout({
    String? addressId,
    String? note,
    int? shippingMethodId,
    int? paymentMethodId,
    List<Map<String, dynamic>>? attributes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (kDebugMode) {
        print('🛒 Updating checkout info');
      }
      
      // Xây dựng request body theo API specification
      final Map<String, dynamic> requestBody = {};
      
      // Thêm các thông tin theo format mới
      if (addressId != null) requestBody['address_id'] = addressId;
      if (note != null) requestBody['note'] = note;
      if (shippingMethodId != null) requestBody['shipping_method_id'] = shippingMethodId;
      if (paymentMethodId != null) requestBody['payment_method_id'] = paymentMethodId;
      
      // Thêm các thuộc tính bổ sung nếu được cung cấp
      if (attributes != null && attributes.isNotEmpty) {
        requestBody['attributes'] = attributes;
      }
      
      if (kDebugMode) {
        print('🛒 Checkout update request: $requestBody');
      }
      
      // Gửi request PUT đến API
      final response = await _apiService.put('/api/client/checkout', requestBody);
      
      if (kDebugMode) {
        print('🛒 Checkout update response: $response');
        print('🛒 Full update response data: ${response['data']}');
        print('🛒 Update response code: ${response['code']}');
        print('🛒 Update response message: ${response['message']}');
      }
      
      if (response['code'] == 200 && response['data'] != null) {
        // Cập nhật dữ liệu checkout trong bộ nhớ
        _checkoutData = response['data'];
        _error = null;
        
        if (kDebugMode) {
          print('✅ Checkout updated successfully');
          print('   Total: ${getTotalPrice(_checkoutData)}');
        }
        
        notifyListeners();
        return _checkoutData;
      } else {
        _error = response['message'] ?? 'Failed to update checkout information';
        if (kDebugMode) {
          print('❌ Error updating checkout: $_error');
        }
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ Exception updating checkout: $e');
      }
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Complete checkout and create order
  Future<Map<String, dynamic>?> completeCheckout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (kDebugMode) {
        print('🛒 Completing checkout');
      }
      
      // Gửi request POST đến API endpoint /complete
      final response = await _apiService.post('/api/client/checkout/complete', {});
      
      if (kDebugMode) {
        print('🛒 Checkout complete response: $response');
        print('🛒 Full complete response data: ${response['data']}');
        print('🛒 Complete response code: ${response['code']}');
        print('🛒 Complete response message: ${response['message']}');
      }
      
      if (response['code'] == 202 && response['data'] != null) {
        // Trả về thông tin đơn hàng
        final orderData = response['data'];
        
        if (kDebugMode) {
          print('✅ Checkout completed successfully');
          print('   Order data: $orderData');
        }
        
        // Reset checkout data sau khi hoàn tất
        _checkoutData = null;
        
        notifyListeners();
        return orderData;
      } else {
        _error = response['message'] ?? 'Failed to complete checkout';
        if (kDebugMode) {
          print('❌ Error completing checkout: $_error');
        }
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ Exception completing checkout: $e');
      }
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Calculate total price with selected shipping method
  double calculateTotalWithShipping(Map<String, dynamic>? data, int? selectedShippingMethodId) {
    if (data == null) return 0.0;
    
    try {
      // Get base subtotal
      final double subtotal = getSubtotal(data);
      
      // Get discount amount
      final double discount = getDiscountAmount(data);
      
      // Get shipping cost based on selected method
      double shippingCost = 0.0;
      if (selectedShippingMethodId != null) {
        final shippingMethods = getShippingMethods(data);
        for (var method in shippingMethods) {
          final methodId = method['id'];
          if (methodId == selectedShippingMethodId) {
            shippingCost = method['price'] is num ? (method['price'] as num).toDouble() : 0.0;
            break;
          }
        }
      } else {
        shippingCost = getShippingCost(data);
      }
      
      // Calculate and return total
      return subtotal + shippingCost - discount;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error calculating total with shipping: $e');
      }
      return 0.0;
    }
  }
  
  // Helper method to convert to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }
} 