import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../models/notification_model.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Notification Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: notification.getColor().withOpacity(0.2),
                  child: Icon(notification.getIcon(), color: notification.getColor()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification.title,
                    style: AppStyles.heading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (notification.imageUrl != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: AssetImage(notification.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Text(
              notification.message,
              style: AppStyles.bodyText,
            ),
            const SizedBox(height: 16),
            Text(
              'Date: ${_formatDate(notification.timestamp)}',
              style: AppStyles.bodyTextSmall.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}