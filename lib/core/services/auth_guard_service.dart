import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/services/auth_service.dart';

/// Service to manage access rights to app features
class AuthGuardService {
  final AuthService _authService;

  AuthGuardService(this._authService);

  /// List of features requiring authentication
  static const List<String> requiresAuthFeatures = [
    // 'Order' is removed to allow unauthenticated users to view products
    'Exchange',
    'Cart',
    'Tracking',
    'Points',
    'Redeem',
    'Member',
    'Profile',
    'Rewards',
    'Checkout',
    'Notifications',
    // 'ProductDetail' and 'Order' are not included to allow unauthenticated users to view products
  ];

  /// List of routes requiring authentication
  static const List<String> requiresAuthRoutes = [
    '/cart',
    '/checkout',
    '/orders',
    '/order-detail',
    '/profile',
    '/profile/points',
    '/profile/edit',
    '/profile/address-book',
    '/profile/rewards',
  ];

  /// Check if a feature requires authentication
  bool featureRequiresAuth(String featureName) {
    return requiresAuthFeatures.contains(featureName);
  }

  /// Check if a route requires authentication
  bool routeRequiresAuth(String routeName) {
    return requiresAuthRoutes.any((route) => routeName.startsWith(route));
  }

  /// Check and redirect user to login screen if needed
  /// Returns true if user has access (logged in or no login required)
  /// Returns false if user is not logged in and has been redirected to login
  bool checkAccess(BuildContext context, String featureOrRoute, {bool isRoute = false}) {
    final bool requiresAuth = isRoute 
      ? routeRequiresAuth(featureOrRoute) 
      : featureRequiresAuth(featureOrRoute);
    
    if (requiresAuth && !_authService.isAuthenticated) {
      _showLoginRequiredDialog(context);
      return false;
    }
    
    return true;
  }

  /// Show login required dialog
  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('You need to login to use this feature'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
  
  /// Check and navigate in widget use cases
  /// Used for cases like clicking on icons, buttons, etc.
  void checkAndNavigate(
    BuildContext context, 
    String featureName, 
    Widget destination
  ) {
    if (!featureRequiresAuth(featureName) || _authService.isAuthenticated) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => destination),
      );
    } else {
      _showLoginRequiredDialog(context);
    }
  }
} 