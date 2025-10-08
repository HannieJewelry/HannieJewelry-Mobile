import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';


class SecurityScreen extends StatelessWidget {
  const SecurityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Safety & Security'),
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
              const Text(
                '1. Purpose and Scope of Information Collection',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hannie Jewelry app does not sell, share or exchange customers\' personal information collected on the website with any third party.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'The personal information collected will only be used by the company to provide products and services to customers.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'When you register to receive information, chat with staff, submit comments, and enter information to make purchases, the personal information that Hannie Jewelry app collects includes: Full name, Address, Phone number, Email...',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'In addition to personal information, there is service information: Product name, Quantity, Product delivery time...',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '2. Scope of Information Use',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Personal information collected will only be used by Hannie Jewelry app within the company and for one or all of the following purposes:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                '- Customer support\n- Providing information related to services\n- Processing orders and providing services and information through our website as requested by you\n- We may send information about new products, services, information about upcoming events or recruitment information if you register to receive email notifications.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}