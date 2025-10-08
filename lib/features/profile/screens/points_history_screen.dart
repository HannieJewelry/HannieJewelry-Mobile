import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class PointsHistoryScreen extends StatelessWidget {
  const PointsHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Points History'),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Total Points',
                      style: AppStyles.bodyText,
                    ),
                    const Spacer(),
                    Text(
                      '0',
                      style: AppStyles.heading.copyWith(color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Points History',
                style: AppStyles.heading,
              ),
              const SizedBox(height: 16),
              _buildHistoryList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    // Simulating empty list
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No points history',
            style: AppStyles.bodyText.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );

    // When there is data, you can use the following code:
    /*
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '+10 points',
                      style: AppStyles.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '01/01/2023',
                      style: AppStyles.bodyText.copyWith(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #12345',
                  style: AppStyles.bodyText,
                ),
              ],
            ),
          ),
        );
      },
    );
    */
  }
}