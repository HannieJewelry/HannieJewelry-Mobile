import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';


class BlogScreen extends StatelessWidget {
  const BlogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Blog'),
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
              _buildBlogItem(
                context: context,
                title: 'OPEN "SURPRISE BOX" FOR SPECIAL OFFERS',
                subtitle: 'Up to 2,500,000 VND',
                date: '15/06/2023',
              ),
              _buildBlogItem(
                context: context,
                title: 'KOREAN "PURE" SILVER JEWELRY',
                subtitle: 'Latest fashion trends',
                date: '10/06/2023',
              ),
              _buildBlogItem(
                context: context,
                title: 'SUMMER PROMOTION',
                subtitle: 'Discounts up to 50%',
                date: '05/06/2023',
              ),
              _buildBlogItem(
                context: context,
                title: 'NEW COLLECTION',
                subtitle: 'Modern and youthful style',
                date: '01/06/2023',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlogItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              'assets/images/placeholder.png',
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppStyles.heading,
                      ),
                    ),
                    Text(
                      date,
                      style: AppStyles.bodyTextSmall.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: AppStyles.bodyText,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Loading blog details...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        'View details',
                        style: AppStyles.bodyTextSmall.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 