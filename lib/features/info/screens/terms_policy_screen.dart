import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';


class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Terms & Policies'),
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
                'PAYMENT INFORMATION SECURITY POLICY',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Security Commitment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '- The card payment system is provided by payment partners ("Payment Partners") that have been legally licensed to operate in Vietnam. Accordingly, card payment security standards at Hannie Jewelry ensure compliance with industry security standards.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '2. Security Regulations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '- Payment transaction policy using international cards and domestic cards (internet banking) ensures compliance with the security standards of Payment Partners including:\n\n• Customer financial information will be protected throughout the transaction process using SSL (Secure Sockets Layer) protocol.\n\n• Payment information data security standard certification (PCI DSS) provided by Trustwave.\n\n• One-time password (OTP) sent via SMS to ensure account access is authenticated.\n\n• MD5 128-bit encryption standard.\n\n• Principles and regulations on information security in the banking and finance industry as regulated by the State Bank of Vietnam.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}