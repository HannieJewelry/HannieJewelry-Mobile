import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';


class ServiceGuideScreen extends StatelessWidget {
  const ServiceGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Service Guide'),
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
                'PAYMENT POLICY',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment methods for purchasing on Hannie Jewelry App are as follows:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Payment method when purchasing at Hannie Jewelry. Cash on Delivery Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Only applicable to areas where we support free delivery or direct payment at: 23/100 Doi Can Street, Doi Can Ward, Ba Dinh District, Hanoi, Vietnam',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '2. Prepayment methods: Money transfer, bank transfer, direct cash payment at our office. Bank transfer method.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Customers can visit the nearest branch to make a payment, our staff will guide you. Please note that when making a payment, you must have a receipt from the Company, with the seal and signature of the Chief Accountant or Company Director.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '*Note: Orders valued at 20 million VND or more that require a VAT invoice must be paid by bank transfer to the company account. Please call our sales staff before transferring for further guidance if needed. And only transfer money to the account numbers listed below to ensure your transaction is as secure as possible.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}