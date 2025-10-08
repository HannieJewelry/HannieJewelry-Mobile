import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../info/screens/beginner_guide_screen.dart';
import '../../info/screens/company_info_screen.dart';
import '../../info/screens/security_screen.dart';
import '../../info/screens/service_guide_screen.dart';
import '../../info/screens/terms_policy_screen.dart';
import 'promotions_screen.dart'; // Add this import

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Support Center'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Get help with your issues',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a topic you are interested in',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSupportItem(
              'Company Information',
              Icons.info_outline,
              context,
            ),
            _buildSupportItem(
              'Service Guide',
              Icons.lightbulb_outline,
              context,
            ),
            _buildSupportItem(
              'Safety & Security',
              Icons.security_outlined,
              context,
            ),
            _buildSupportItem(
              'For Beginners',
              Icons.person_outline,
              context,
            ),
            _buildSupportItem(
              'Terms & Policies',
              Icons.description_outlined,
              context,
            ),
            _buildSupportItem(
              'Promotions',
              Icons.card_giftcard,
              context,
            ),
            // const SizedBox(height: 24),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       const Text(
            //         'You may be interested in',
            //         style: TextStyle(
            //           fontSize: 16,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //       const SizedBox(height: 16),
            //       Row(
            //         children: [
            //           const Text('NEWS'),
            //           const Spacer(),
            //           Icon(
            //             Icons.arrow_forward_ios,
            //             size: 16,
            //             color: Colors.grey[600],
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportItem(String title, IconData icon, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),
        title: Text(title),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[600],
        ),
        onTap: () {
          // Navigate to the corresponding screen based on title
          if (title == 'Company Information') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CompanyInfoScreen()),
            );
          } else if (title == 'Service Guide') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ServiceGuideScreen()),
            );
          } else if (title == 'Safety & Security') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SecurityScreen()),
            );
          } else if (title == 'For Beginners') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BeginnerGuideScreen()),
            );
          } else if (title == 'Terms & Policies') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TermsPolicyScreen()),
            );
          } else if (title == 'Promotions') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PromotionsScreen()),
            );
          } else {
            // Show notification for other items
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('The $title feature is under development')),
            );
          }
        },
      ),
    );
  }
}