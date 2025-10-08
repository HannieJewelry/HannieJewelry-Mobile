import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tracking_order_service.dart';
import '../screens/order_tracking_screen.dart';

class OrderTrackingDemoWidget extends StatelessWidget {
  const OrderTrackingDemoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Tracking Demo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test the order tracking functionality with sample cart token',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Test with sample cart token
                      final trackingService = Provider.of<TrackingOrderService>(context, listen: false);
                      trackingService.fetchTrackingOrders('92ec81c32dde49438dfeb819a5861e4b');
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderTrackingScreen(
                            cartToken: '92ec81c32dde49438dfeb819a5861e4b',
                          ),
                        ),
                      );
                    },
                    child: const Text('Test with Sample Token'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderTrackingScreen(),
                        ),
                      );
                    },
                    child: const Text('Open Tracking Screen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
