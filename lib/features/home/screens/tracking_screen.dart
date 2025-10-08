import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../orders/screens/order_detail_screen.dart';
import '../../orders/services/order_service.dart';
import '../../auth/services/auth_service.dart';
import '../../checkout/models/order_model.dart';
import '../../auth/screens/login_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _cartTokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSearchByToken = false;
  OrderModel? _trackedOrder;
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  Future<void> _loadOrders() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      await orderService.fetchOrders();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load orders: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _searchOrder() async {
    final orderId = _orderIdController.text.trim();
    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an order ID'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      final order = await orderService.getOrderById(orderId);
      
      setState(() {
        _isLoading = false;
      });
      
      if (order != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(
              orderId: orderId,
            ),
          ),
        ).then((_) => _loadOrders());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order not found'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching for order: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  Future<void> _trackOrderByToken() async {
    final cartToken = _cartTokenController.text.trim();
    if (cartToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã token'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _trackedOrder = null;
      _errorMessage = null;
    });
    
    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      final result = await orderService.trackOrder(cartToken);
      
      if (result != null) {
        print('✅ Tracking result: $result');
        
        try {
          // Tạo OrderModel từ kết quả API
          final order = OrderModel.fromMap(result);
          setState(() {
            _isLoading = false;
            _trackedOrder = order;
          });
          
          // Chuyển đến màn hình chi tiết đơn hàng với ID từ kết quả tracking
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(
                orderId: order.id,
              ),
            ),
          );
        } catch (e) {
          print('❌ Error converting tracking result to OrderModel: $e');
          setState(() {
            _isLoading = false;
            _errorMessage = 'Không thể hiển thị thông tin đơn hàng: ${e.toString()}';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không tìm thấy đơn hàng với mã token này';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi khi tìm kiếm đơn hàng: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _orderIdController.dispose();
    _cartTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final orderService = Provider.of<OrderService>(context);
    final orders = orderService.orders;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Order History'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tab switcher
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSearchByToken = false;
                                  _trackedOrder = null;
                                  _errorMessage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: !_isSearchByToken ? AppColors.primary : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Order ID',
                                  style: TextStyle(
                                    fontWeight: !_isSearchByToken ? FontWeight.bold : FontWeight.normal,
                                    color: !_isSearchByToken ? AppColors.primary : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSearchByToken = true;
                                  _errorMessage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _isSearchByToken ? AppColors.primary : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Cart Token',
                                  style: TextStyle(
                                    fontWeight: _isSearchByToken ? FontWeight.bold : FontWeight.normal,
                                    color: _isSearchByToken ? AppColors.primary : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      if (!_isSearchByToken) ...[
                        // Order ID search section
                        Text(
                          'Enter Order ID',
                          style: AppStyles.heading,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                            hintText: 'Order ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _searchOrder,
                          ),
                        ),
                          controller: _orderIdController,
                        onSubmitted: (_) => _searchOrder(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Recent Orders',
                        style: AppStyles.heading,
                      ),
                      const SizedBox(height: 16),
                      _errorMessage != null
                          ? Center(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : !authService.isAuthenticated
                              ? _buildLoginPrompt()
                              : orders.isEmpty
                                  ? _buildEmptyOrdersView()
                                  : _buildOrdersList(orders),
                      ] else ...[
                        // Cart token search section
                        Text(
                          'Nhập Cart Token',
                          style: AppStyles.heading,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Nhập mã token',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: _trackOrderByToken,
                            ),
                          ),
                          controller: _cartTokenController,
                          onSubmitted: (_) => _trackOrderByToken(),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          'Hướng dẫn',
                          style: AppStyles.heading,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Để tìm kiếm đơn hàng của bạn, vui lòng nhập cart token nhận được từ email xác nhận đơn hàng hoặc từ nhân viên hỗ trợ.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'You have no orders yet',
            style: AppStyles.bodyText.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Please login to view your orders',
            style: AppStyles.bodyTextSmall.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              ).then((_) => _loadOrders());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyOrdersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'You don\'t have any orders yet',
            style: AppStyles.bodyText.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders will appear here after you make a purchase',
            style: AppStyles.bodyTextSmall.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/product_browse');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrdersList(List<OrderModel> orders) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(
                    orderId: order.id,
                  ),
                ),
              ).then((_) => _loadOrders());
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 8),
                      _buildOrderStatus(order),
                    ],
                  ),
                  const Divider(),
                  
                  // Product items summary (if available)
                  if (order.items.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${order.items.length} ${order.items.length > 1 ? 'items' : 'item'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Order date if available
                  if (order.note != null && order.note!.contains("Created:")) ...[
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _extractCreationDate(order.note!),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Total amount row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        order.totalAmount > 0 
                            ? '${_formatCurrency(order.totalAmount)}' 
                            : 'Đang tính toán',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to extract creation date from note
  String _extractCreationDate(String note) {
    try {
      final createdMatch = RegExp(r'Created: ([^\n]+)').firstMatch(note);
      if (createdMatch != null && createdMatch.groupCount >= 1) {
        final rawDate = createdMatch.group(1) ?? '';
        // Parse the ISO date format and format as a readable date
        if (rawDate.isNotEmpty) {
          final dateTime = DateTime.parse(rawDate);
          return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        }
      }
      return 'Không có thông tin';
    } catch (e) {
      print('Error extracting date: $e');
      return 'Không xác định';
    }
  }
  
  Widget _buildOrderStatus(OrderModel order) {
    // Map status from order if available
    String statusText = 'Processing';
    Color statusColor = Colors.orange;
    
    // Check for status in note field
    if (order.note != null) {
      // Kiểm tra financial status
      if (order.note!.contains("financial_status: PAID")) {
        statusText = 'Paid';
        statusColor = Colors.green;
      } else if (order.note!.contains("financial_status: PENDING")) {
        statusText = 'Pending Payment';
        statusColor = Colors.orange;
      } else if (order.note!.contains("financial_status: REFUNDED")) {
        statusText = 'Refunded';
        statusColor = Colors.red;
      }
      
      // Kiểm tra fulfillment status - ưu tiên hiển thị hơn financial status
      if (order.note!.contains("fulfillment_status: FULFILLED")) {
        statusText = 'Fulfilled';
        statusColor = Colors.blue;
      } else if (order.note!.contains("fulfillment_status: UNFULFILLED")) {
        statusText = 'Unfulfilled';
        statusColor = Colors.orange;
      } else if (order.note!.contains("fulfillment_status: DELIVERED")) {
        statusText = 'Delivered';
        statusColor = Colors.green;
      }
      
      // Kiểm tra order processing status - ưu tiên hiển thị cao nhất
      if (order.note!.contains("order_processing_status: COMPLETED")) {
        statusText = 'Completed';
        statusColor = Colors.green;
      } else if (order.note!.contains("order_processing_status: PROCESSING")) {
        statusText = 'Processing';
        statusColor = Colors.blue;
      } else if (order.note!.contains("order_processing_status: PENDING")) {
        statusText = 'Pending';
        statusColor = Colors.orange;
      } else if (order.note!.contains("order_processing_status: CANCELLED")) {
        statusText = 'Cancelled';
        statusColor = Colors.red;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
  
  String _formatCurrency(double price) {
    if (price == 0) return '0 đ';
    
    String priceString = price.toStringAsFixed(0);
    final result = StringBuffer();
    for (int i = 0; i < priceString.length; i++) {
      if ((priceString.length - i) % 3 == 0 && i > 0) {
        result.write('.');
      }
      result.write(priceString[i]);
    }
    return '${result.toString()} đ';
  }
}