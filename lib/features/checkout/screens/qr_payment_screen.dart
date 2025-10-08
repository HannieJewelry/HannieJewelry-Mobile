import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../app/app_config.dart';
import 'package:ably_flutter/ably_flutter.dart' as ably;

import 'order_success_screen.dart';

class QRPaymentScreen extends StatefulWidget {
  final String orderId;
  final double orderTotal;
  final String bankName;
  final String accountNumber;
  final String accountName;

  const QRPaymentScreen({
    Key? key,
    required this.orderId,
    required this.orderTotal,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  }) : super(key: key);

  @override
  State<QRPaymentScreen> createState() => _QRPaymentScreenState();
}

class _QRPaymentScreenState extends State<QRPaymentScreen> {
  String paymentStatus = "Unpaid";
  Timer? _paymentCheckTimer;
  final int _checkIntervalSeconds = 10; // Check payment status every 10 seconds
  String? _orderCode;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Ably real-time client
  ably.Realtime? _ablyClient;
  ably.RealtimeChannel? _ablyChannel;
  static const String _ablyApiKey = "C8j12g.D6pO4Q:gEZ0L3y2NmQA79kfWfKbbYz3jt70xfoTL2PUIiiOZ5s";

  @override
  void initState() {
    super.initState();
    // Fetch order details first
    _fetchOrderDetails();
    // Initialize Ably realtime client
    _initializeAblyClient();
  }

  @override
  void dispose() {
    _paymentCheckTimer?.cancel();
    // Cleanup Ably resources
    _cleanupAblyResources();
    super.dispose();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      // Sử dụng URL API thực tế
      final baseUrl = AppConfig.apiBaseUrl; 
      
      print('Fetching order details for ID: ${widget.orderId}');
      
      // Tối đa 3 lần retry nếu gặp lỗi API
      int retryCount = 0;
      const maxRetries = 13;
      bool success = false;
      dynamic apiData;
      
      while (retryCount < maxRetries && !success) {
        try {
          // Gọi API thực để lấy thông tin đơn hàng
          final response = await http.get(
            Uri.parse('$baseUrl/api/orders/${widget.orderId}'),
            headers: {'Content-Type': 'application/json'},
          );

          print('API Response: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['data'] != null) {
              apiData = data;
              success = true;
            } else {
              print('API data not found, retrying...');
              retryCount++;
              await Future.delayed(const Duration(seconds: 1));
            }
          } else {
            print('API error: ${response.statusCode} ${response.body}');
            retryCount++;
            await Future.delayed(const Duration(seconds: 1));
          }
        } catch (e) {
          print('API request error: $e');
          retryCount++;
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      
      if (success && apiData != null) {
        // Đã nhận được dữ liệu hợp lệ
        setState(() {
          _orderCode = apiData['data']['order_code'];
          _isLoading = false;
          print('Order code received: $_orderCode');
        });
        
        // Thiết lập kênh Ably với order_code nếu đã kết nối
        if (_orderCode != null && 
            _ablyClient != null && 
            _ablyClient?.connection.state == ably.ConnectionState.connected) {
          _setupAblyChannel(_orderCode!);
        }
        
        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order information retrieved successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Bắt đầu kiểm tra trạng thái thanh toán
        _startPaymentStatusCheck();
      } else {
        // Nếu không thể lấy dữ liệu sau nhiều lần thử, hiện fallback UI
        setState(() {
          _orderCode = null; // Không gán giá trị mặc định
          _isLoading = false;
        });
        
        // Thiết lập kênh Ably với giá trị mặc định
        // _setupAblyChannel("DH23");
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Unable to retrieve order information'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Vẫn bắt đầu kiểm tra trạng thái thanh toán
        _startPaymentStatusCheck();
      }
    } catch (e) {
      // Log lỗi để dễ gỡ lỗi
      print('Error fetching order details: $e');
      
      setState(() {
        _orderCode = null;
        _isLoading = false;
      });
      
      // Thiết lập kênh Ably với giá trị mặc định
      // _setupAblyChannel("DH23");
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Vẫn bắt đầu kiểm tra trạng thái thanh toán
      _startPaymentStatusCheck();
    }
  }

  void _startPaymentStatusCheck() {
    // Check immediately once
    _checkPaymentStatus();
    
    // Then set up periodic checks
    _paymentCheckTimer = Timer.periodic(
      Duration(seconds: _checkIntervalSeconds), 
      (_) => _checkPaymentStatus()
    );
  }

  Future<void> _checkPaymentStatus() async {
    try {
      // Kiểm tra trạng thái thanh toán qua API
      final baseUrl = AppConfig.apiBaseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/${widget.orderId}/status'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Checking payment status...');
      
      // Trong môi trường thực tế, bạn sẽ xử lý phản hồi API để cập nhật trạng thái
      // Ở đây chúng ta chỉ giả lập việc kiểm tra
      
      // Nếu phát hiện thanh toán thành công từ API
      /*
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data']?['payment_status'] == 'paid') {
          _handlePaymentConfirmation();
        }
      }
      */
    } catch (e) {
      print('Error checking payment status: $e');
    }
  }

  void _markAsPaid() {
    setState(() {
      paymentStatus = "Paid";
    });
    _paymentCheckTimer?.cancel();
    
    // Gửi xác nhận thanh toán qua Ably
    _sendPaymentConfirmation();
    
    // Gọi API để thông báo thanh toán thành công
    _simulatePaymentConfirmation();
    
    // Navigate to success screen after a short delay
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(
              orderId: widget.orderId,
            ),
          ),
        );
      }
    });
  }
  
  // Giả lập việc gọi API để xác nhận thanh toán
  Future<void> _simulatePaymentConfirmation() async {
    try {
      final baseUrl = AppConfig.apiBaseUrl;
      final data = {
        'order_id': widget.orderId,
        'payment_status': 'paid',
        'paid_at': DateTime.now().toIso8601String(),
      };
      
      // Giả lập việc gọi API
      print('Simulating payment confirmation API call: ${json.encode(data)}');
      
      // Trong môi trường thực tế, bạn sẽ gọi API để cập nhật trạng thái thanh toán
      /*
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders/${widget.orderId}/confirm-payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      
      if (response.statusCode == 200) {
        print('Payment confirmation API call successful');
      } else {
        print('Payment confirmation API call failed: ${response.statusCode}');
      }
      */
    } catch (e) {
      print('Error in payment confirmation: $e');
    }
  }

  // Khởi tạo Ably client và kết nối
  Future<void> _initializeAblyClient() async {
    try {
      print('Initializing Ably client with key: $_ablyApiKey');
      
      // Khởi tạo ClientOptions với API key
      final clientOptions = ably.ClientOptions(key: _ablyApiKey);
      
      // Tạo Realtime instance
      _ablyClient = ably.Realtime(options: clientOptions);
      
      // Lắng nghe sự kiện kết nối
      _ablyClient?.connection
          .on()
          .listen((ably.ConnectionStateChange stateChange) {
            print('Ably connection state changed: ${stateChange.current}');
            
            // Khi kết nối thành công, thiết lập kênh nếu có order code
            if (stateChange.current == ably.ConnectionState.connected && 
                _orderCode != null) {
              _setupAblyChannel(_orderCode!);
            }
          });
      
      print('Ably client initialized');
    } catch (e) {
      print('Error initializing Ably client: $e');
    }
  }
  
  // Thiết lập kênh Ably và đăng ký sự kiện
  void _setupAblyChannel(String orderCode) {
    if (_ablyClient == null) {
      print('Cannot setup Ably channel: Client not initialized');
      return;
    }
    
    try {
      final channelName = 'order-$orderCode';
      print('Setting up Ably channel: $channelName');
      
      // Lấy instance của kênh
      _ablyChannel = _ablyClient?.channels.get(channelName);
      
      // Đăng ký lắng nghe sự kiện thanh toán
      _ablyChannel?.subscribe()
          .listen((ably.Message message) {
            if (message.name == 'order-paid') {
              print('Received payment confirmation: ${message.data}');
              _handlePaymentConfirmation();
            }
          });
      
      print('Successfully subscribed to Ably channel');
    } catch (e) {
      print('Error setting up Ably channel: $e');
    }
  }
  
  // Xử lý khi nhận được xác nhận thanh toán
  void _handlePaymentConfirmation() {
    if (mounted) {
      setState(() {
        paymentStatus = "Paid";
      });
      
      // Dừng kiểm tra trạng thái thanh toán định kỳ
      _paymentCheckTimer?.cancel();
      
      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment has been confirmed!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Chuyển đến màn hình thành công sau một khoảng thời gian ngắn
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderSuccessScreen(
                orderId: widget.orderId,
              ),
            ),
          );
        }
      });
    }
  }
  
  // Gửi thông báo thanh toán thành công
  void _sendPaymentConfirmation() {
    if (_ablyChannel == null || _orderCode == null) {
      print('Cannot send payment confirmation: Ably channel or order code not available');
      return;
    }
    
    try {
      // Tạo dữ liệu thanh toán
      final paymentData = {
        'order_id': widget.orderId,
        'order_code': _orderCode,
        'paid_at': DateTime.now().toIso8601String(),
        'status': 'paid',
      };
      
      // Tạo message và publish
      final message = ably.Message(name: 'order-paid', data: json.encode(paymentData));
      _ablyChannel?.publish(message: message);
      
      print('Payment confirmation sent to Ably channel');
    } catch (e) {
      print('Error sending payment confirmation: $e');
    }
  }
  
  // Giải phóng tài nguyên Ably
  void _cleanupAblyResources() {
    try {
      // Đóng kênh
      if (_ablyChannel != null) {
        _ablyChannel?.detach();
      }
      
      // Đóng kết nối
      if (_ablyClient != null) {
        _ablyClient?.close();
      }
      
      print('Ably resources cleaned up');
    } catch (e) {
      print('Error cleaning up Ably resources: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }
    
    // Tạo mã thanh toán từ order_code hoặc id đơn hàng
    final String paymentCode = _orderCode ?? "DH23";
    final String displayOrderCode = _orderCode ?? "ORDER-${widget.orderId.substring(0, 8)}...";
    
    // Generate VietQR URL
    final bankId = "970422"; // VietinBank BIN
    final accountNumber = widget.accountNumber;
    final amount = widget.orderTotal.toInt();
    
    // Tạo nội dung thanh toán, ưu tiên sử dụng order_code nếu có
    final orderInfo = "SEVQR ${paymentCode}";
    final addInfo = Uri.encodeComponent(orderInfo);
    final template = "compact";
    final qrUrl = "https://api.vietqr.io/image/$bankId-$accountNumber-$template.jpg?amount=$amount&addInfo=$addInfo";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: paymentStatus == "Paid" 
        ? _buildPaymentSuccessful(displayOrderCode)
        : _buildPaymentPending(qrUrl, orderInfo, displayOrderCode),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading order details...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentPending(String qrUrl, String orderInfo, String displayOrderCode) {
    return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
            // VietQR QR Code
              Container(
              width: 250,
              height: 250,
                decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  qrUrl,
                  width: 230,
                  height: 230,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / 
                              loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 50, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text('Could not load QR code', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Payment instructions
              const Text(
                'Bank Transfer Instructions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Bank details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                  // _buildInfoRow('Order ID', '#${widget.orderId}'),
                  // const Divider(),
                  // Hiển thị Order Code nếu có, hoặc một phần của Order ID nếu không
                  _buildInfoRow(
                    'Order Code',
                    displayOrderCode,
                    isHighlighted: true
                  ),
                  const Divider(),
                  _buildInfoRow('Total Amount', _formatCurrency(widget.orderTotal), isCopyable: true, copyValue: widget.orderTotal.toInt().toString(), copyTooltip: 'Copy raw amount'),
                    const Divider(),
                  _buildInfoRow('Bank', widget.bankName),
                    const Divider(),
                  _buildInfoRow('Account Number', widget.accountNumber, isCopyable: true, copyTooltip: 'Copy account number only'),
                    const Divider(),
                  _buildInfoRow('Account Name', widget.accountName),
                    const Divider(),
                  _buildInfoRow('Payment Status', 'Waiting for payment...'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            // Transfer content notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Important',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                    'Please include the following text in your transfer description:',
                      style: TextStyle(fontSize: 14),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                    Text(
                                orderInfo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: orderInfo));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied to clipboard')),
                                  );
                                },
                                child: const Icon(
                                  Icons.copy,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // I've paid button
              SizedBox(
                width: double.infinity,
              height: 50,
                child: ElevatedButton(
                onPressed: _markAsPaid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('I\'ve Completed Payment'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'After completing the payment, the system will automatically verify and proceed.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSuccessful(String displayOrderCode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 100,
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Order ID: #${widget.orderId}',
            style: const TextStyle(fontSize: 16),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Code: ',
                  style: TextStyle(fontSize: 16),
                ),
                Flexible(
                  child: Text(
                    displayOrderCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.orderTotal.toInt().toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Amount copied to clipboard')),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Amount: ${_formatCurrency(widget.orderTotal)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.copy,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Thank you for your purchase!',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderSuccessScreen(
                    orderId: widget.orderId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: const TextStyle(fontSize: 16),
                  ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {
    bool isCopyable = false, 
    bool isHighlighted = false, 
    String? copyValue,
    String? copyTooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: isHighlighted ? 
                      const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary) : 
                      const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
                if (isCopyable) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: copyTooltip ?? 'Copy to clipboard',
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: copyValue ?? value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(copyValue != null 
                              ? 'Raw value copied: ${copyValue ?? value}'
                              : 'Copied to clipboard'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.copy,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
    return '${result.toString()} ₫';
  }
}
