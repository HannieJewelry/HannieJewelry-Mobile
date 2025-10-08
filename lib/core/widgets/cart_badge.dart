import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/cart/services/cart_service.dart';
import '../../features/cart/screens/cart_screen_fixed.dart';
import '../../routes/app_routes.dart';

class CartBadge extends StatelessWidget {
  final int? count;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final Color badgeColor;

  const CartBadge({
    Key? key,
    this.count,
    this.onTap,
    this.onPressed,
    this.badgeColor = AppColors.primary,
  }) : super(key: key);

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You need to login to access your cart'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // If count is provided, use it directly
    if (count != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: onTap ?? onPressed ?? () {
              // Check login before opening cart
              if (authService.isAuthenticated) {
                // Use named navigation instead of direct route
                Navigator.pushNamed(context, Routes.CART);
              } else {
                _showLoginRequiredDialog(context);
              }
            },
          ),
          if (count! > 0)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }

    // Original implementation using CartService
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                // Check login before opening cart
                if (authService.isAuthenticated) {
                  // Use named navigation instead of direct route
                  Navigator.pushNamed(context, Routes.CART);
                } else {
                  _showLoginRequiredDialog(context);
                }
              },
            ),
            if (cartService.itemCount > 0)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${cartService.itemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
