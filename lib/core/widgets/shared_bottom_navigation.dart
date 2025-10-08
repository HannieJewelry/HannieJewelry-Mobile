import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../../routes/app_routes.dart';

class SharedBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const SharedBottomNavigation({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) {
          // Already on current screen, do nothing
          return;
        }

        switch (index) {
          case 0:
            // Navigate to home
            Navigator.of(context).pushReplacementNamed(Routes.HOME);
            break;
          case 1:
            // Navigate to categories/browse
            Navigator.of(context).pushReplacementNamed(Routes.PRODUCT_BROWSE);
            break;
          case 2:
            // Navigate to orders
            Navigator.of(context).pushReplacementNamed(Routes.ORDERS);
            break;
          case 3:
            // Navigate to notifications
            Navigator.of(context).pushReplacementNamed(Routes.NOTIFICATIONS);
            break;
          case 4:
            // Navigate to profile
            Navigator.of(context).pushReplacementNamed(Routes.PROFILE);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
