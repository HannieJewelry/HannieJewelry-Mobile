import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import 'home_screen.dart';
import 'qr_scan_screen.dart';
import '../../cart/screens/cart_screen_backup.dart'; // Corrected import
import '../../profile/screens/profile_screen.dart';


class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({Key? key}) : super(key: key);

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }
  
  void _handleTabChange() {
    if (_tabController.index == 1) {
      // When user selects "My Promotions" tab
      Future.delayed(Duration.zero, () {
        _showLoginDialog();
      });
    }
  }
  
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Notification',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'You need to log in to use this feature',
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    child: const Text(
                      'Confirm',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Gifts'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'My Gifts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: All
          _buildAllPromotionsTab(),
          
          // Tab 2: My Promotions
          _buildMyPromotionsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: 1, // Highlight the promotions tab
        onTap: (index) {
          if (index == 0) {
            // Navigate to Home
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (index == 2) {
            // Navigate to QR Scan
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const QRScanScreen()),
            );
          } else if (index == 3) {
            // Navigate to Cart - use named routes for consistency
            Navigator.of(context).pushReplacementNamed(Routes.CART);
          } else if (index == 4) {
            // Use named routes to properly trigger RouteGuard
            Navigator.of(context).pushReplacementNamed(Routes.PROFILE);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Gifts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'QR Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Your Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      // Loại bỏ FloatingActionButton
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: AppColors.primary,
      //   child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      //   onPressed: () {
      //     Navigator.of(context).push(
      //       MaterialPageRoute(builder: (context) => const QRScanScreen()),
      //     );
      //   },
      // ),
    );
  }
  
  Widget _buildAllPromotionsTab() {
    // This would normally contain a list of promotions
    // For now, we'll just show a placeholder
    return const Center(
      child: Text('No content to display'),
    );
  }
  
  Widget _buildMyPromotionsTab() {
    return Column(
      children: [
        // Login required message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: Colors.orange,
          child: const Text(
            'You need to log in to use this feature',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Empty state message
        const Expanded(
          child: Center(
            child: Text(
              'No content to display',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}