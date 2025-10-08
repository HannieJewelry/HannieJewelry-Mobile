import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/auth_guard_service.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/services/auth_service.dart';
import '../features/home/screens/home_screen.dart';
import '../features/products/screens/product_detail_screen.dart';
import '../features/products/screens/product_browse_screen.dart';
import '../features/cart/screens/cart_screen_fixed.dart';
import '../features/checkout/screens/checkout_screen.dart';
import '../features/checkout/screens/order_success_screen.dart';
import '../features/orders/screens/orders_main_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/info/screens/company_info_screen.dart';
import '../main.dart';
import 'app_routes.dart';
import '../features/checkout/models/order_model.dart'; // Import for OrderModel


class RouteGuard extends StatelessWidget {
  final String routeName;
  final WidgetBuilder builder;

  const RouteGuard({
    Key? key,
    required this.routeName,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authGuard = Provider.of<AuthGuardService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    

    if (authGuard.routeRequiresAuth(routeName) && !authService.isAuthenticated) {

      return LoginScreen(
        redirectRoute: routeName,
      );
    }
    

    return builder(context);
  }
}

class AppPages {
  static const initial = Routes.LOGIN; // Changed from SPLASH to LOGIN to skip splash screen but keep login

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.SPLASH:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const SplashScreen(),
        );
      case Routes.LOGIN:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const LoginScreen(),
        );
      case Routes.HOME:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const HomeScreen(),
        );
      case Routes.PRODUCT_DETAIL:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ProductDetailScreen(
            productHandle: args['productHandle'] as String,
          ),
        );
      case Routes.CART:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => RouteGuard(
            routeName: settings.name!,
            builder: (context) => const CartScreen(),
          ),
        );
      case Routes.CHECKOUT:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => RouteGuard(
            routeName: settings.name!,
            builder: (context) => const CheckoutScreen(),
          ),
        );
      case Routes.ORDER_SUCCESS:
        final args = settings.arguments as String; // Changed from OrderModel to String
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => RouteGuard(
            routeName: settings.name!,
            builder: (context) => OrderSuccessScreen(orderId: args),
          ),
        );
      case Routes.ORDERS:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => RouteGuard(
            routeName: settings.name!,
            builder: (context) => const OrdersMainScreen(),
          ),
        );
      case Routes.ORDER_DETAIL:
        final args = settings.arguments as String;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => RouteGuard(
            routeName: settings.name!,
            builder: (context) => OrderDetailScreen(orderId: args),
          ),
        );
      case Routes.PROFILE:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => RouteGuard(
            routeName: settings.name!,
            builder: (context) => const ProfileScreen(),
          ),
        );
      case Routes.NOTIFICATIONS:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const NotificationsScreen(),
        );
      case Routes.COMPANY_INFO:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const CompanyInfoScreen(),
        );
      case Routes.PRODUCT_BROWSE:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const ProductBrowseScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        );
    }
  }

  static final Map<String, WidgetBuilder> routes = {
    Routes.SPLASH: (context) => const SplashScreen(),
    Routes.LOGIN: (context) => const LoginScreen(),
    Routes.HOME: (context) => const HomeScreen(),
    Routes.PRODUCT_DETAIL: (context) => ProductDetailScreen(
      productHandle: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['productHandle'] as String,
    ),
    Routes.CART: (context) => const CartScreen(),
    Routes.CHECKOUT: (context) => const CheckoutScreen(),
    Routes.ORDER_SUCCESS: (context) => OrderSuccessScreen(orderId: ModalRoute.of(context)!.settings.arguments as String),
    Routes.ORDERS: (context) => const OrdersMainScreen(),
    Routes.ORDER_DETAIL: (context) => OrderDetailScreen(orderId: ModalRoute.of(context)!.settings.arguments as String),
    Routes.PROFILE: (context) => const ProfileScreen(),
    Routes.NOTIFICATIONS: (context) => const NotificationsScreen(),
    Routes.COMPANY_INFO: (context) => const CompanyInfoScreen(),
    Routes.PRODUCT_BROWSE: (context) => const ProductBrowseScreen(),
  };
}