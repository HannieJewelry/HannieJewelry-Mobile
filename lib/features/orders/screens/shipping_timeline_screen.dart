import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../checkout/models/order_model.dart';
import '../services/order_service.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/utils/format_utils.dart';

class ShippingTimelineScreen extends StatefulWidget {
  final String orderId;

  const ShippingTimelineScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<ShippingTimelineScreen> createState() => _ShippingTimelineScreenState();
}

class _ShippingTimelineScreenState extends State<ShippingTimelineScreen> {
  @override
  Widget build(BuildContext context) {
    final orderService = Provider.of<OrderService>(context);
    final authService = Provider.of<AuthService>(context);
    
    // Check authentication
    if (!authService.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFE57373),
          foregroundColor: Colors.white,
          title: const Text('Shipping Method'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Please login to view shipping information',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return FutureBuilder<OrderModel?>(
      future: orderService.getOrderById(widget.orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              title: const Text('Shipping Method'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final order = snapshot.data;
        
        if (order == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              title: const Text('Shipping Method'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Order not found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: const Color(0xFFE57373),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Shipping Method',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
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
                // Order header
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.orderNumber ?? '#${order.id.substring(0, 8)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          _buildStatusBadge(order),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Product info
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/placeholder.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image,
                                    color: Colors.grey[400],
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.items.isNotEmpty ? order.items.first.name : 'Product',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                order.items.isNotEmpty ? FormatUtils.formatCurrency(order.items.first.price) : '0đ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                order.items.isNotEmpty ? 'x${order.items.first.quantity}' : 'x0',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Timeline section
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Status',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._buildTimelineItems(order),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel order button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Handle cancel order
                        _showCancelOrderDialog(context, order);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel Order'),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem({
    required bool isCompleted,
    required bool isActive,
    required String title,
    required String time,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: isCompleted ? Colors.black : Colors.grey[600],
                ),
              ),
              if (time.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  void _showCancelOrderDialog(BuildContext context, OrderModel order) {
    String selectedReason = 'Đổi địa chỉ giao hàng';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Lý do hủy'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Không có nhu cầu mua nữa'),
                    value: 'Không có nhu cầu mua nữa',
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Thay đổi phương thức thanh toán'),
                    value: 'Thay đổi phương thức thanh toán',
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Đổi địa chỉ giao hàng'),
                    value: 'Đổi địa chỉ giao hàng',
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Tìm thấy sản phẩm giá tốt hơn'),
                    value: 'Tìm thấy sản phẩm giá tốt hơn',
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Chưa áp mã giảm giá'),
                    value: 'Chưa áp mã giảm giá',
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Người bán không hỗ trợ'),
                    value: 'Người bán không hỗ trợ',
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Lý do khác'),
                    value: 'Lý do khác',
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: () => _cancelOrder(context, order, selectedReason),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Send'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cancelOrder(BuildContext context, OrderModel order, String reason) async {
    if (!mounted) return;
    
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    navigator.pop(); // Close dialog
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      final success = await orderService.cancelOrder(
        order.id,
        'Customer',
        reason,
      );
      
      if (!mounted) return;
      
      navigator.pop(); // Close loading dialog
      
      if (success) {
        if (mounted) {
          navigator.pop({'cancelled': true}); // Go back to order detail
          
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Order has been cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Cannot cancel order. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      navigator.pop(); // Close loading dialog
      
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget _buildStatusBadge(OrderModel order) {
    final status = order.orderProcessingStatus?.toLowerCase() ?? 'pending';
    final financialStatus = order.financialStatus?.toLowerCase() ?? 'pending';
    
    Color backgroundColor;
    Color textColor;
    String text;

    // Determine status based on both order_processing_status and financial_status
    if (financialStatus == 'pending') {
      backgroundColor = const Color(0xFFFFF3CD);
      textColor = const Color(0xFF856404);
      text = 'Pending Payment';
    } else {
      switch (status) {
        case 'pending':
          backgroundColor = Colors.amber[100]!;
          textColor = Colors.amber[800]!;
          text = 'Pending';
          break;
        case 'processing':
          backgroundColor = Colors.blue[100]!;
          textColor = Colors.blue[700]!;
          text = 'Processing';
          break;
        case 'confirmed':
          backgroundColor = Colors.teal[100]!;
          textColor = Colors.teal[700]!;
          text = 'Confirmed';
          break;
        case 'completed':
          backgroundColor = Colors.green[100]!;
          textColor = Colors.green[700]!;
          text = 'Completed';
          break;
        case 'cancelled':
          backgroundColor = Colors.grey[200]!;
          textColor = Colors.grey[700]!;
          text = 'Cancelled';
          break;
        default:
          backgroundColor = Colors.grey[100]!;
          textColor = Colors.grey[700]!;
          text = 'Unknown';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  List<Widget> _buildTimelineItems(OrderModel order) {
    final status = order.orderProcessingStatus?.toLowerCase() ?? 'pending';
    final financialStatus = order.financialStatus?.toLowerCase() ?? 'pending';
    final fulfillmentStatus = order.fulfillmentStatus?.toLowerCase() ?? 'unfulfilled';
    
    final items = <Widget>[];
    
    // Timeline stages based on actual order status
    final stages = [
      {
        'title': 'Pending Payment',
        'completed': true, // Always show as completed since order exists
        'time': FormatUtils.formatDateTimeForTimeline(order.createdAt),
      },
      {
        'title': 'Processing',
        'completed': financialStatus == 'paid' && (status == 'processing' || status == 'confirmed' || status == 'completed'),
        'time': financialStatus == 'paid' ? FormatUtils.formatDateTimeForTimeline(order.updatedAt) : '',
      },
      {
        'title': 'Shipping',
        'completed': fulfillmentStatus == 'fulfilled' || status == 'completed',
        'time': fulfillmentStatus == 'fulfilled' ? FormatUtils.formatDateTimeForTimeline(order.updatedAt) : '',
      },
      {
        'title': 'Delivered',
        'completed': status == 'completed',
        'time': status == 'completed' ? FormatUtils.formatDateTimeForTimeline(order.updatedAt) : '',
      },
    ];

    for (int i = 0; i < stages.length; i++) {
      final stage = stages[i];
      items.add(
        _buildTimelineItem(
          isCompleted: stage['completed'] as bool,
          isActive: false,
          title: stage['title'] as String,
          time: stage['time'] as String,
          isLast: i == stages.length - 1,
        ),
      );
    }

    return items;
  }
}
