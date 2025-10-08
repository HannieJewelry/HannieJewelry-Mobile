import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/shared_bottom_navigation.dart';
import '../../../routes/app_routes.dart';
import '../../auth/services/auth_service.dart';
import '../../checkout/models/order_model.dart';
import '../services/order_service.dart';
import 'order_detail_screen.dart';

class OrdersMainScreen extends StatefulWidget {
  const OrdersMainScreen({Key? key}) : super(key: key);

  @override
  State<OrdersMainScreen> createState() => _OrdersMainScreenState();
}

class _OrdersMainScreenState extends State<OrdersMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated) {
        setState(() {
          _errorMessage = 'Please login to view your orders';
          _isInitialLoading = false;
        });
        return;
      }

      final orderService = Provider.of<OrderService>(context, listen: false);
      await orderService.fetchOrders();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load orders. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFE57373),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            height: 44,
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide.none,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
              indicator: const BoxDecoration(),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Processing'),
                Tab(text: 'Delivered'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
        ),
      ),
      body: !authService.isAuthenticated
          ? _buildLoginPrompt()
          : _isInitialLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrdersList('processing'),
                        _buildOrdersList('delivered'),
                        _buildOrdersList('cancelled'),
                      ],
                    ),
      bottomNavigationBar: const SharedBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
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
            'Vui lòng đăng nhập để xem đơn hàng',
            style: TextStyle(
              color: Colors.grey.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
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
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.red.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String status) {
    return Consumer<OrderService>(
      builder: (context, orderService, _) {
        final orders = _filterOrdersByStatus(orderService.orders, status);

        if (orders.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: _loadOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order, status);
            },
          ),
        );
      },
    );
  }

  List<OrderModel> _filterOrdersByStatus(List<OrderModel> orders, String status) {
    return orders.where((order) {
      final note = order.note?.toLowerCase() ?? '';
      
      // Debug logging
      if (order.id.contains('3070536a') || note.contains('order_processing_status')) {
        print('🔍 Debug Order ${order.id}:');
        print('   Note: "$note"');
        print('   Status filter: $status');
      }
      
      // Check for cancelled orders - new format uses CANCEL
      bool isCancelled = note.contains('cancelled') || 
                        note.contains('canceled') || 
                        note.contains('order_processing_status: cancel') ||
                        note.contains('order_processing_status: CANCEL');
      
      // Check for completed/delivered orders - new format uses COMPLETED and FULFILLED
      bool isDelivered = note.contains('delivered') || 
                        note.contains('completed') || 
                        note.contains('fulfillment_status: fulfilled') ||
                        note.contains('fulfillment_status: FULFILLED') ||
                        note.contains('order_processing_status: completed') ||
                        note.contains('order_processing_status: COMPLETED');
      
      bool shouldShow = false;
      switch (status) {
        case 'processing':
          // Show orders that are pending, processing, confirmed, or self_delivery (not cancelled or completed)
          shouldShow = !isCancelled && !isDelivered && 
                 (note.contains('order_processing_status: pending') || 
                  note.contains('order_processing_status: PENDING') ||
                  note.contains('order_processing_status: processing') ||
                  note.contains('order_processing_status: PROCESSING') ||
                  note.contains('order_processing_status: confirmed') ||
                  note.contains('order_processing_status: CONFIRMED') ||
                  note.contains('order_processing_status: self_delivery') ||
                  note.contains('order_processing_status: SELF_DELIVERY') ||
                  note.contains('fulfillment_status: unfulfilled') ||
                  note.contains('fulfillment_status: UNFULFILLED') ||
                  note.contains('financial_status: pending') ||
                  note.contains('financial_status: PENDING') ||
                  note.contains('pending') || 
                  note.contains('processing') || 
                  note.contains('unfulfilled') || 
                  note.isEmpty);
          break;
        case 'delivered':
          // Show completed/delivered orders that are not cancelled
          shouldShow = !isCancelled && isDelivered;
          break;
        case 'cancelled':
          // Show cancelled orders
          shouldShow = isCancelled;
          break;
        default:
          shouldShow = true;
      }
      
      return shouldShow;
    }).toList();
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;
    
    switch (status) {
      case 'processing':
        message = 'No orders in processing';
        icon = Icons.hourglass_empty;
        break;
      case 'delivered':
        message = 'No delivered orders';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        message = 'No cancelled orders';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'No orders';
        icon = Icons.shopping_bag_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, String status) {
    // Use order.orderNumber field directly
    String orderNumber = order.orderNumber ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: order.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order number section with beige background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F1E8), // Beige/cream background
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order ID: ${orderNumber.isNotEmpty ? orderNumber : order.id.substring(0, 16)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shipping info with yellow truck icon
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFC107), // Yellow background
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Hannie Jewelry',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      _buildStatusBadge(order),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Delivery time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Estimated delivery: Before 12:00 PM 09/09/2025',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Product images section
                  if (order.items.isNotEmpty)
                    _buildProductImages(order.items),
                  
                  const SizedBox(height: 16),
                  
                  // Separator line
                  Container(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bottom section with total and button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${order.items.length} product${order.items.length != 1 ? 's' : ''}: ${_formatCurrency(order.totalAmount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _navigateToOrderDetail(order),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImages(List<OrderItem> items) {
    // Show up to 2 images, positioned left and right if there are 2 items
    if (items.length == 1) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
        ),
        child: items.first.imageUrl.startsWith('http')
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  items.first.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image,
                      color: Colors.grey[400],
                    );
                  },
                ),
              )
            : Icon(
                Icons.image,
                color: Colors.grey[400],
              ),
      );
    } else if (items.length >= 2) {
      return Row(
        children: [
          // Left image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: items[0].imageUrl.startsWith('http')
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      items[0].imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image,
                          color: Colors.grey[400],
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.image,
                    color: Colors.grey[400],
                  ),
          ),
          const Spacer(),
          // Right image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: items[1].imageUrl.startsWith('http')
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      items[1].imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image,
                          color: Colors.grey[400],
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.image,
                    color: Colors.grey[400],
                  ),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  bool _canCancelOrder(OrderModel order, String status) {
    // Only allow cancellation for orders in processing status
    return status == 'processing' && 
           (order.note?.contains('order_processing_status: pending') == true ||
            order.note?.contains('order_processing_status: processing') == true);
  }

  void _showCancelOrderDialog(OrderModel order) {
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
                    onPressed: () => _cancelOrder(order, selectedReason),
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

  Future<void> _cancelOrder(OrderModel order, String reason) async {
    Navigator.of(context).pop(); // Close dialog
    
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
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (success) {
        // Switch to cancelled tab
        _tabController.animateTo(2);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order has been cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot cancel order. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusBadge(OrderModel order) {
    // Extract actual order_processing_status from API response
    String actualStatus = _extractOrderProcessingStatus(order);
    
    Color backgroundColor;
    Color textColor;
    String text;

    switch (actualStatus.toUpperCase()) {
      case 'PENDING':
        backgroundColor = Colors.amber[100]!;
        textColor = Colors.amber[800]!;
        text = 'Pending';
        break;
      case 'PROCESSING':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        text = 'Processing';
        break;
      case 'CONFIRMED':
        backgroundColor = Colors.teal[100]!;
        textColor = Colors.teal[700]!;
        text = 'Confirmed';
        break;
      case 'SELF_DELIVERY':
        backgroundColor = Colors.deepPurple[100]!;
        textColor = Colors.deepPurple[700]!;
        text = 'Self Delivery';
        break;
      case 'COMPLETED':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        text = 'Completed';
        break;
      case 'FAILED':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        text = 'Failed';
        break;
      case 'CANCEL':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        text = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        text = actualStatus.isNotEmpty ? actualStatus : 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  String _extractOrderProcessingStatus(OrderModel order) {
    final note = order.note ?? '';
    
    // Extract order_processing_status from note
    final match = RegExp(r'order_processing_status:\s*([^\n]+)', caseSensitive: false).firstMatch(note);
    if (match != null) {
      return match.group(1)?.trim() ?? '';
    }
    
    return '';
  }

  void _navigateToOrderDetail(OrderModel order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: order.id),
      ),
    );
    
    // If order was cancelled, switch to cancelled tab
    // No need to refresh orders since OrderService already updated the local state
    if (result != null && result['cancelled'] == true) {
      _tabController.animateTo(2); // Switch to cancelled tab (index 2)
    }
  }

  String _formatCurrency(double price) {
    String priceString = price.toStringAsFixed(0);
    final result = StringBuffer();
    for (int i = 0; i < priceString.length; i++) {
      if ((priceString.length - i) % 3 == 0 && i > 0) {
        result.write('.');
      }
      result.write(priceString[i]);
    }
    return '${result.toString()} ₫';
  }
}
