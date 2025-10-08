import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/auth/services/auth_service.dart';
import '../features/cart/services/cart_service.dart';
import '../features/orders/services/order_service.dart';
import '../features/notifications/services/notification_service.dart';
import '../features/products/services/product_service.dart';
import '../features/profile/services/profile_service.dart';
import '../features/profile/services/address_service.dart';
import '../features/profile/services/product_detail_service.dart';
import '../features/profile/services/collections_service.dart';
import '../features/profile/services/tracking_order_service.dart';
import '../features/checkout/services/checkout_service.dart';
import '../core/services/api_service.dart';
import '../core/services/auth_guard_service.dart';

class AppProvider {
  static AuthService? _authService;
  static AuthGuardService? _authGuardService;
  static AddressService? _addressService;
  static ApiService? _apiService;
  static CartService? _cartService;
  static CheckoutService? _checkoutService;
  
  static Future<void> init() async {
    print('🚀 Initializing AppProvider...');
    _apiService = ApiService();
    _authService = AuthService(_apiService!);
    
    print('🔑 Initializing AuthService...');
    await _authService!.initialize();
    
    print('🔒 Setting up AuthGuardService...');
    _authGuardService = AuthGuardService(_authService!);
    
    print('📍 Setting up AddressService...');
    _addressService = AddressService(_apiService!, authService: _authService!);
    
    print('🛒 Setting up CartService...');
    _cartService = CartService(apiService: _apiService!);
    // Pre-load cart data
    try {
      await _cartService!.fetchCart();
      print('🛒 Cart initialized with ${_cartService!.itemCount} items');
    } catch (e) {
      print('❌ Error initializing cart: $e');
    }
    
    print('🧾 Setting up CheckoutService...');
    _checkoutService = CheckoutService(apiService: _apiService!);
    
    print('✅ AppProvider initialization complete');
    
    // Print authentication status
    print('🔑 Authentication status: ${_authService!.isAuthenticated ? 'Authenticated' : 'Not authenticated'}');
    if (_authService!.isAuthenticated) {
      print('👤 Current user: ${_authService!.currentUser?.name} (${_authService!.currentUser?.id})');
    }
  }
  
  static List<SingleChildWidget> get providers => [
    ChangeNotifierProvider.value(value: _authService!),
    Provider.value(value: _authGuardService!),
    Provider.value(value: _apiService!),
    ChangeNotifierProvider.value(value: _cartService!),
    ChangeNotifierProvider.value(value: _checkoutService!),
    ChangeNotifierProxyProvider2<AuthService, ApiService, OrderService>(
      create: (context) => OrderService(
        Provider.of<AuthService>(context, listen: false),
        Provider.of<ApiService>(context, listen: false),
      ),
      update: (context, auth, api, previous) => OrderService(auth, api),
    ),
    ChangeNotifierProxyProvider<AuthService, NotificationService>(
      create: (context) => NotificationService(authService: Provider.of<AuthService>(context, listen: false)),
      update: (context, auth, previous) => NotificationService(authService: auth),
    ),
    ChangeNotifierProxyProvider<ApiService, ProductService>(
      create: (context) => ProductService(Provider.of<ApiService>(context, listen: false)),
      update: (context, api, previous) => ProductService(api),
    ),
    ChangeNotifierProxyProvider2<AuthService, ApiService, ProfileService>(
      create: (context) => ProfileService(
        Provider.of<AuthService>(context, listen: false),
        Provider.of<ApiService>(context, listen: false),
      ),
      update: (context, auth, api, previous) => ProfileService(auth, api),
    ),
    ChangeNotifierProxyProvider2<AuthService, ApiService, AddressService>(
      create: (context) => AddressService(
        Provider.of<ApiService>(context, listen: false),
        authService: Provider.of<AuthService>(context, listen: false),
      ),
      update: (context, auth, api, previous) {
        // Chỉ tạo mới nếu chưa được khởi tạo, nếu không sử dụng instance hiện có
        if (_addressService != null) {
          return _addressService!;
        }
        return AddressService(api, authService: auth);
      },
    ),
    ChangeNotifierProxyProvider2<AuthService, ApiService, ProductDetailService>(
      create: (context) => ProductDetailService(
        Provider.of<AuthService>(context, listen: false),
        Provider.of<ApiService>(context, listen: false),
      ),
      update: (context, auth, api, previous) => ProductDetailService(auth, api),
    ),
    ChangeNotifierProxyProvider2<AuthService, ApiService, CollectionsService>(
      create: (context) => CollectionsService(
        Provider.of<AuthService>(context, listen: false),
        Provider.of<ApiService>(context, listen: false),
      ),
      update: (context, auth, api, previous) => CollectionsService(auth, api),
    ),
    ChangeNotifierProxyProvider2<ApiService, CartService, TrackingOrderService>(
      create: (context) => TrackingOrderService(
        Provider.of<ApiService>(context, listen: false),
        cartService: Provider.of<CartService>(context, listen: false),
      ),
      update: (context, api, cart, previous) => TrackingOrderService(api, cartService: cart),
    ),
  ];
}