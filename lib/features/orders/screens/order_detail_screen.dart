import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../checkout/models/order_model.dart';
import '../services/order_service.dart';
import '../../auth/services/auth_service.dart';
import 'shipping_timeline_screen.dart';
import 'payment_method_screen.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/constants/app_colors.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final orderService = Provider.of<OrderService>(context);
    final authService = Provider.of<AuthService>(context);
    
    // Check authentication
    if (!authService.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Order Details'),
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
                'Please login to view order details',
                style: TextStyle(
                  color: Colors.grey.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to login screen
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login'),
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
              backgroundColor: AppColors.primary,
              title: const Text('Order Details'),
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
              backgroundColor: AppColors.primary,
              title: const Text('Order Details'),
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
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Order Information',
              style: TextStyle(
                color: Colors.white,
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
                // Order number and status header
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
                            ),
                          ),
                          _buildStatusBadge(order),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            FormatUtils.formatDateTime(order.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShippingTimelineScreen(orderId: widget.orderId),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                const Text(
                                  'View shipping information',
                                  style: TextStyle(
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Delivery info section
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFFF8E1),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFC107),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Home delivery',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_getShippingName(order)} - ${_getShippingPhone(order)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFullShippingAddress(order),
                        style: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Shipping package',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Home delivery',
                          ),
                          Text(
                            FormatUtils.formatCurrency(_getShippingFee(order)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Note',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: Text(
                          _getOriginalNote(order),
                          style: TextStyle(
                            color: _getOriginalNote(order) != 'No note' ? Colors.black87 : Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Product section
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected products',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.imageUrl.isNotEmpty && item.imageUrl.startsWith('http')
                                    ? Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.image,
                                            color: Colors.grey[400],
                                          );
                                        },
                                      )
                                    : Image.asset(
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
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quantity: ${item.quantity}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              FormatUtils.formatCurrency(item.price * item.quantity),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Payment section
                // Container(
                //   width: double.infinity,
                //   color: Colors.white,
                //   padding: const EdgeInsets.all(16),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Text(
                //         'Payment',
                //         style: TextStyle(
                //           fontWeight: FontWeight.w600,
                //         ),
                //       ),
                //       const SizedBox(height: 16),
                //       _buildPaymentRow('Subtotal', FormatUtils.formatCurrency(order.totalAmount - _getShippingFee(order))),
                //       _buildPaymentRow('Shipping fee', FormatUtils.formatCurrency(_getShippingFee(order))),
                //       const Divider(),
                //       _buildPaymentRow(
                //         'Total', 
                //         FormatUtils.formatCurrency(order.totalAmount),
                //         isTotal: true,
                //       ),
                //     ],
                //   ),
                // ),

                // const SizedBox(height: 16),

                // Payment and Cancel buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Cancel button (if cancellable)
                      if (_canCancelOrder(order))
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showCancelOrderDialog(context, order),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel Order'),
                          ),
                        ),
                      
                      // Spacing between buttons
                      if (_canCancelOrder(order)) const SizedBox(width: 12),
                      
                      // // Payment button
                      // Expanded(
                      //   child: ElevatedButton(
                      //     onPressed: () => _navigateToPaymentMethod(context, order),
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: AppColors.primary,
                      //       foregroundColor: Colors.white,
                      //       padding: const EdgeInsets.symmetric(vertical: 16),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(8),
                      //       ),
                      //     ),
                      //     child: const Text(
                      //       'Payment',
                      //       style: TextStyle(
                      //         fontWeight: FontWeight.w600,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
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

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  bool _canCancelOrder(OrderModel order) {
    // Only allow cancellation for orders in processing status
    return order.note?.contains('order_processing_status: pending') == true ||
           order.note?.contains('order_processing_status: processing') == true;
  }

  void _showCancelOrderDialog(BuildContext context, OrderModel order) {
    String selectedReason = 'Change delivery address';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cancellation reason'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: const Text('No longer need to buy'),
                        value: 'No longer need to buy',
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Change payment method'),
                        value: 'Change payment method',
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Change delivery address'),
                        value: 'Change delivery address',
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Found a better price'),
                        value: 'Found a better price',
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Forgot to apply discount code'),
                        value: 'Forgot to apply discount code',
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Seller does not support'),
                        value: 'Seller does not support',
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _cancelOrder(context, order, selectedReason),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send'),
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
    
    // Store the navigator reference before any async operations
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
      
      // Close loading dialog safely
      try {
        navigator.pop();
      } catch (e) {
        print('Error closing loading dialog: $e');
      }
      
      if (success) {
        if (mounted) {
          // Go back to orders list and pass result to switch to cancelled tab
          try {
            navigator.pop({'cancelled': true});
            
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Order has been cancelled successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            print('Error navigating back: $e');
          }
        }
      } else {
        if (mounted) {
          try {
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Cannot cancel order. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          } catch (e) {
            print('Error showing error message: $e');
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog safely
      try {
        navigator.pop();
      } catch (navError) {
        print('Error closing loading dialog in catch: $navError');
      }
      
      if (mounted) {
        try {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (snackError) {
          print('Error showing error snackbar: $snackError');
        }
      }
    }
  }

  String _getOriginalNote(OrderModel order) {
    if (order.note == null || order.note!.isEmpty) {
      return 'No note';
    }
    
    // Extract only the original note (first line before any mapped info)
    final lines = order.note!.split('\n');
    final originalNote = lines.first.trim();
    
    // If the original note contains mapped data, return 'No note'
    if (originalNote.contains('order_processing_status:') || 
        originalNote.contains('financial_status:') ||
        originalNote.contains('Order Number:') ||
        originalNote.contains('Created:') ||
        originalNote.contains('Payment:')) {
      return 'No note';
    }
    
    return originalNote.isNotEmpty ? originalNote : 'No note';
  }

  String _getShippingName(OrderModel order) {
    // Try to get from shipping_address first, then from note_attributes
    if (order.shippingAddress != null && order.shippingAddress!['name'] != null && order.shippingAddress!['name'].toString().isNotEmpty) {
      return order.shippingAddress!['name'].toString();
    }
    
    // Fallback to note_attributes
    final fullNameAttr = order.noteAttributes?.firstWhere(
      (attr) => attr['name'] == 'full_name',
      orElse: () => <String, dynamic>{},
    );
    
    return fullNameAttr?['value'] ?? order.recipientName;
  }

  String _getShippingPhone(OrderModel order) {
    // Try to get from shipping_address first, then from note_attributes
    if (order.shippingAddress != null && order.shippingAddress!['phone'] != null && order.shippingAddress!['phone'].toString().isNotEmpty) {
      return order.shippingAddress!['phone'].toString();
    }
    
    // Fallback to note_attributes
    final phoneAttr = order.noteAttributes?.firstWhere(
      (attr) => attr['name'] == 'phone_number',
      orElse: () => <String, dynamic>{},
    );
    
    return phoneAttr?['value'] ?? order.recipientPhone;
  }

  String _getFullShippingAddress(OrderModel order) {
    if (order.shippingAddress != null) {
      final address = order.shippingAddress!;
      final parts = <String>[];
      
      if (address['address1'] != null && address['address1'].toString().isNotEmpty) parts.add(address['address1'].toString());
      if (address['ward'] != null && address['ward'].toString().isNotEmpty) parts.add(address['ward'].toString());
      if (address['district'] != null && address['district'].toString().isNotEmpty) parts.add(address['district'].toString());
      if (address['province'] != null && address['province'].toString().isNotEmpty) parts.add(address['province'].toString());
      
      return parts.join(', ');
    }
    
    return order.recipientAddress;
  }

  double _getShippingFee(OrderModel order) {
    // Check shipping_lines for shipping cost
    if (order.shippingLines != null && order.shippingLines!.isNotEmpty) {
      final shippingLine = order.shippingLines!.first;
      return shippingLine['price']?.toDouble() ?? 0.0;
    }
    
    return order.shippingFee;
  }

  String _getPaymentMethodName(OrderModel order) {
    // Get payment method from note_attributes
    final paymentMethodAttr = order.noteAttributes?.firstWhere(
      (attr) => attr['name'] == 'payment_method_id',
      orElse: () => <String, dynamic>{},
    );
    
    final paymentMethodId = paymentMethodAttr?['value'];
    
    // Map payment method ID to name
    switch (paymentMethodId) {
      case '1':
        return 'Chuyển khoản';
      case '2':
        return 'Tiền mặt';
      case '3':
        return 'Thẻ tín dụng';
      default:
        return order.paymentMethod?.toString() ?? 'Chuyển khoản';
    }
  }

  IconData _getPaymentMethodIcon(OrderModel order) {
    final paymentMethodName = _getPaymentMethodName(order);
    
    switch (paymentMethodName) {
      case 'Chuyển khoản':
        return Icons.account_balance;
      case 'Tiền mặt':
        return Icons.money;
      case 'Thẻ tín dụng':
        return Icons.credit_card;
      default:
        return Icons.account_balance;
    }
  }

  Color _getPaymentMethodColor(OrderModel order) {
    final paymentMethodName = _getPaymentMethodName(order);
    
    switch (paymentMethodName) {
      case 'Chuyển khoản':
        return Colors.blue[700]!;
      case 'Tiền mặt':
        return Colors.green[700]!;
      case 'Thẻ tín dụng':
        return Colors.purple[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  String _getPaymentStatus(OrderModel order) {
    final financialStatus = order.financialStatus?.toLowerCase() ?? 'pending';
    
    switch (financialStatus) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Awaiting Payment';
      case 'refunded':
        return 'Refunded';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Awaiting Payment';
    }
  }

  Color _getPaymentStatusColor(OrderModel order) {
    final financialStatus = order.financialStatus?.toLowerCase() ?? 'pending';
    
    switch (financialStatus) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return const Color(0xFFE57373);
      case 'refunded':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return const Color(0xFFE57373);
    }
  }

  String _getQRCodeData(OrderModel order) {
    final paymentMethodName = _getPaymentMethodName(order);
    
    if (paymentMethodName == 'Chuyển khoản') {
      // Generate bank transfer QR code data
      final orderNumber = order.orderNumber ?? order.id;
      final amount = order.totalAmount.toInt();
      
      // Standard Vietnamese QR Pay format
      return 'BANK_TRANSFER|ORDER:$orderNumber|AMOUNT:$amount|CURRENCY:VND';
    } else {
      // Default order QR code
      return 'ORDER_${order.id}';
    }
  }

  void _navigateToPaymentMethod(BuildContext context, OrderModel order) async {
    final selectedPaymentMethod = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodScreen(
          orderId: order.id,
          totalAmount: order.totalAmount,
        ),
      ),
    );

    if (selectedPaymentMethod != null) {
      // Handle the selected payment method
      // You can update the order with the new payment method here
      print('Selected payment method: $selectedPaymentMethod');
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
      text = 'Awaiting Payment';
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
        ),
      ),
    );
  }
}