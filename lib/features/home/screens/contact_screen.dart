import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Contact Us'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContactItem(
                icon: Icons.phone,
                title: 'Hotline',
                content: '1900 1234',
                onTap: () => _makePhoneCall('1900 1234'),
              ),
              _buildContactItem(
                icon: Icons.email,
                title: 'Email',
                content: 'support@example.com',
                onTap: () => _sendEmail('support@example.com'),
              ),
              _buildContactItem(
                icon: Icons.location_on,
                title: 'Address',
                content: '123 ABC Street, XYZ District, Ho Chi Minh City',
                onTap: () => _openMap('123 ABC Street, XYZ District, Ho Chi Minh City'),
              ),
              _buildContactItem(
                icon: Icons.access_time,
                title: 'Working Hours',
                content: 'Mon - Fri: 8:00 AM - 5:30 PM\nSat: 8:00 AM - 12:00 PM',
                onTap: () {}, // Không có hành động khi nhấn vào giờ làm việc
              ),
              // const SizedBox(height: 24),
              // Text(
              //   'Send us a message',
              //   style: AppStyles.heading,
              // ),
              // const SizedBox(height: 16),
              // TextField(
              //   decoration: InputDecoration(
              //     hintText: 'Full Name',
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 16),
              // TextField(
              //   decoration: InputDecoration(
              //     hintText: 'Email',
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 16),
              // TextField(
              //   decoration: InputDecoration(
              //     hintText: 'Phone Number',
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 16),
              // TextField(
              //   maxLines: 5,
              //   decoration: InputDecoration(
              //     hintText: 'Message',
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 24),
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     onPressed: () {
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         const SnackBar(
              //           content: Text('Your message has been sent'),
              //           duration: Duration(seconds: 2),
              //         ),
              //       );
              //     },
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: AppColors.primary,
              //       padding: const EdgeInsets.symmetric(vertical: 16),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //     ),
              //     child: const Text('Send Message'),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // Gọi điện thoại
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(' ', ''),
    );
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Could not launch $launchUri');
    }
  }

  // Gửi email
  Future<void> _sendEmail(String emailAddress) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Could not launch $launchUri');
    }
  }

  // Mở Google Maps
  Future<void> _openMap(String address) async {
    final Uri launchUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $launchUri');
    }
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String content,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: AppStyles.bodyTextSmall,
                    ),
                  ],
                ),
              ),
              // Thêm icon chỉ thị có thể nhấn
              if (title != 'Working Hours')
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
