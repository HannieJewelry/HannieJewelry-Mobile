import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/shared_bottom_navigation.dart';
import '../../../routes/app_routes.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../cart/screens/cart_screen_backup.dart';
import '../../home/screens/branch_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../home/screens/promotions_screen.dart';
import '../../home/screens/qr_scan_screen.dart';
import '../../home/screens/support_center_screen.dart';
import '../../home/screens/tracking_screen.dart';
import '../../orders/screens/order_history_screen.dart';
import 'address_book_screen.dart';
import 'order_tracking_screen.dart';
import 'delete_account_screen.dart';
import 'edit_profile_screen.dart';
import 'favorite_products_screen.dart';
import 'points_screen.dart';
import 'referral_screen.dart';
import '../../home/screens/contact_screen.dart';
import '../../home/screens/feedback_screen.dart';
import '../../orders/screens/return_exchange_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // Get login information from AuthService
    final authService = Provider.of<AuthService>(context);
    final isLoggedIn = authService.isAuthenticated;
    final user = authService.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with user info and login/edit button
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.primary,
                child: Row(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!) as ImageProvider
                          : null,
                      child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey[300],
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn ? user?.name ?? 'User' : 'Guest',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            isLoggedIn ? user?.phone ?? '' : 'Phone number not verified',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Login/Edit button
                    TextButton(
                      onPressed: () {
                        if (isLoggedIn) {
                          // Navigate to edit profile screen
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                          ).then((updated) {
                            // Refresh the screen if profile was updated
                            if (updated == true) {
                              setState(() {});
                            }
                          });
                        } else {
                          // Navigate to login screen
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            isLoggedIn ? 'Edit' : 'Login',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isLoggedIn ? Icons.edit : Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Menu items
              const SizedBox(height: 16),
              // _buildMenuItem(Icons.track_changes_outlined, 'Order Tracking'),
              _buildMenuItem(Icons.location_on_outlined, 'Address Book'),
              _buildMenuItem(Icons.phone, 'Contact'),
              // _buildMenuItem(Icons.people_outline, 'Refer a Friend'),
              // _buildMenuItem(Icons.help_outline, 'Support Center'),
              // _buildMenuItem(Icons.delete_forever, 'Delete Account'),
              
              // Add logout button if logged in
              if (isLoggedIn) _buildLogoutButton(),
              
              // App info
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Version:'),
                        const Spacer(),
                        Text(
                          'Beta 1.0.0',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Build:'),
                        const Spacer(),
                        Text(
                          '2025-07-24',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80), // Space for bottom navigation
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SharedBottomNavigation(currentIndex: 4),
    );
  }
  
  // Method to handle menu item
  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        final authService = Provider.of<AuthService>(context, listen: false);
        final isLoggedIn = authService.isAuthenticated;
        
        if (title == 'Order History') {
          if (isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TrackingScreen()),
            );
          } else {
            _showLoginRequiredDialog();
          }
        // } else if (title == 'Order Tracking') {
        //   // Order tracking doesn't require login since it uses cart token
        //   // But we can still show a better experience for logged in users
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(builder: (context) => const OrderTrackingScreen()),
        //   );
        // } else if (title == 'Favorite Products') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FavoriteProductsScreen()),
          );
        } else if (title == 'Address Book') {
          if (isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddressBookScreen()),
            );
          } else {
            _showLoginRequiredDialog();
          }
        } else if (title == 'Points History') {
          if (isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PointsScreen()),
            );
          } else {
            _showLoginRequiredDialog();
          }
        } else if (title == 'Refer a Friend') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReferralScreen()),
          );
        } else if (title == 'Support Center') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SupportCenterScreen()),
          );
        } else if (title == 'Delete Account') {
          if (isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DeleteAccountScreen()),
            );
          } else {
            _showLoginRequiredDialog();
          }
        } else if (title == 'Exchange') {
          if (isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReturnExchangeScreen()),
            );
          } else {
            _showLoginRequiredDialog();
          }
        } else if (title == 'Contact') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactScreen()),
          );
        } else if (title == 'Feedback') {

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FeedbackScreen()),
          );
        }
      },
    );
  }
  
  // Method to build logout button
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[400],
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          _showLogoutConfirmDialog();
        },
        child: const Text(
          'Logout',
          style: TextStyle(color: Colors.white
          ),
        ),
      ),
    );
  }
  
  // Show login required dialog
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Login Required',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Please login to use this feature',
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    child: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
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
  
  // Show logout confirmation dialog
  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirm',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    child: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Logout
                      final authService = Provider.of<AuthService>(context, listen: false);
                      authService.logout();
                      
                      // Close dialog and refresh screen
                      Navigator.of(context).pop();
                      setState(() {});
                    },
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
}