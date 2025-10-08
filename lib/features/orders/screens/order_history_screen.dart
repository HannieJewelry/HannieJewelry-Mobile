import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';

import '../../../features/auth/services/auth_service.dart';
import '../../checkout/models/order_model.dart';
import '../services/order_service.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isInitialLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });
    
    try {
      print('🔄 Loading orders from OrderHistoryScreen');
      
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated) {
        setState(() {
          _errorMessage = 'Please login to view your order history';
          _isInitialLoading = false;
        });
        return;
      }
      
      print('👤 Current user: ${authService.currentUser?.name} (${authService.currentUser?.phone})');
      
      final orderService = Provider.of<OrderService>(context, listen: false);
      await orderService.fetchOrders();
      
      print('✅ Orders loaded successfully: ${orderService.orders.length} orders');
    } catch (e) {
      print('❌ Error loading orders: $e');
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
    final orderService = Provider.of<OrderService>(context);
    final orders = orderService.orders;
    final isLoading = orderService.isLoading;

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
          // Debug button to reload orders
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrders,
          ),
          // Debug button to check auth status
          IconButton(
            icon: const Icon(Icons.security, color: Colors.white),
            onPressed: () {
              final isAuth = authService.isAuthenticated;
              final token = authService.currentUser?.id ?? 'No ID';
              final name = authService.currentUser?.name ?? 'No Name';
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Auth: ${isAuth ? 'Yes' : 'No'}, User: $name, ID: $token',
                    style: const TextStyle(fontSize: 12),
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            },
          ),
        ],
      ),
      body: !authService.isAuthenticated
          ? _buildLoginPrompt()
          : _isInitialLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: isLoading && !_isInitialLoading
                      ? Stack(
                          children: [
                            _buildOrdersList(orders),
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.1),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _errorMessage != null
                          ? Center(
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
                                      fontSize: 16,
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
                                    child: const Text('Try Again'),
                                  ),
                                ],
                              ),
                            )
                          : _buildOrdersList(orders),
                ),
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
            'Please login to view your order history',
            style: TextStyle(
              fontSize: 16,
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
    );
  }
  
  Widget _buildOrdersList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'You don\'t have any orders yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders will appear here after you make a purchase',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/product_browse');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Shopping'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: _loadOrders,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: orders.length,
      padding: const EdgeInsets.all(16),
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
              ).then((_) {
                // Reload orders when returning from detail screen
                _loadOrders();
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _buildOrderStatus(order),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (order.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No items in this order',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(item.name),
                              ),
                              Text(
                                '${_formatCurrency(item.price * item.quantity)} VND',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )),
                  const Divider(),
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
                        '${_formatCurrency(order.totalAmount)} VND',
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

  Widget _buildOrderStatus(OrderModel order) {
    // In reality, you would get the status from the order
    // This is a simulation of the order status
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Delivered',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
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
    return result.toString();
  }
}