import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_config.dart';


class ApiService {
  String? _authToken;
  final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  // Getters for external access
  String get baseUrl => AppConfig.apiBaseUrl;
  Map<String, String> get headers => Map.from(_headers);

  ApiService();


  void setAuthToken(String token) {
    _authToken = token;
    _headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _authToken = null;
    _headers.remove('Authorization');
  }

  // Get request headers with JWT authentication only
  Map<String, String> _getRequestHeaders() {
    final headers = Map<String, String>.from(_headers);
    
    if (kDebugMode && _authToken != null) {
      print('🔐 Using JWT authentication');
    }
    
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}${endpoint.startsWith('/') ? endpoint : '/$endpoint'}');
    final requestHeaders = _getRequestHeaders();
    
    // Debug logging
    if (kDebugMode) {
      print('🌐 API GET Request:');
      print('   URL: $url');
      print('   Headers: $requestHeaders');
    }
    
    try {
      final response = await http.get(url, headers: requestHeaders)
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));
      
      
      // Debug response
      if (kDebugMode) {
        print('📥 API GET Response:');
        print('   Status: ${response.statusCode}');
        print('   Headers: ${response.headers}');
        print('   Body: ${response.body}');
      }
      
      return _processResponse(response);
    } catch (e) {
      print('❌ API GET Error: $e');
      print('   Endpoint: $endpoint');
      print('   Full URL: $url');
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}${endpoint.startsWith('/') ? endpoint : '/$endpoint'}');
    final requestHeaders = _getRequestHeaders();
    
    // Enhanced debug logging
    if (kDebugMode) {
      print('🌐 API POST Request:');
      print('   URL: $url');
      print('   Headers: $requestHeaders');
      print('   Body: ${json.encode(data)}');
      print('   Body Size: ${utf8.encode(json.encode(data)).length} bytes');
    }
    
    try {
      final response = await http.post(
        url,
        headers: requestHeaders,
        body: utf8.encode(json.encode(data)),
      ).timeout(Duration(milliseconds: AppConfig.connectTimeout));
      
      
      // Enhanced debug response
      if (kDebugMode) {
        print('📥 API POST Response:');
        print('   Status: ${response.statusCode}');
        print('   Headers: ${response.headers}');
        print('   Body: ${response.body}');
        print('   Body Length: ${response.body.length}');
      }
      
      return _processResponse(response);
    } catch (e) {
      print('❌ API POST Error: $e');
      print('   Endpoint: $endpoint');
      print('   Full URL: $url');
      print('   Request Data: ${json.encode(data)}');
      print('   Error Type: ${e.runtimeType}');
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}${endpoint.startsWith('/') ? endpoint : '/$endpoint'}');
    final requestHeaders = _getRequestHeaders();
    
    // Enhanced debug logging
    if (kDebugMode) {
      print('🌐 API PUT Request:');
      print('   URL: $url');
      print('   Headers: $requestHeaders');
      print('   Body: ${json.encode(data)}');
      print('   Body Size: ${utf8.encode(json.encode(data)).length} bytes');
    }
    
    try {
      final response = await http.put(
        url,
        headers: requestHeaders,
        body: utf8.encode(json.encode(data)),
      ).timeout(Duration(milliseconds: AppConfig.connectTimeout));
      
      
      // Enhanced debug response
      if (kDebugMode) {
        print('📥 API PUT Response:');
        print('   Status: ${response.statusCode}');
        print('   Headers: ${response.headers}');
        print('   Body: ${response.body}');
        print('   Body Length: ${response.body.length}');
      }
      
      return _processResponse(response);
    } catch (e) {
      print('❌ API PUT Error: $e');
      print('   Endpoint: $endpoint');
      print('   Full URL: $url');
      print('   Request Data: ${json.encode(data)}');
      print('   Error Type: ${e.runtimeType}');
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}${endpoint.startsWith('/') ? endpoint : '/$endpoint'}');
    final requestHeaders = _getRequestHeaders();
    
    if (kDebugMode) {
      print('🌐 API DELETE Request:');
      print('   URL: $url');
      print('   Headers: $requestHeaders');
    }
    
    try {
      final response = await http.delete(url, headers: requestHeaders)
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));
      
      
      if (kDebugMode) {
        print('📥 API DELETE Response:');
        print('   Status: ${response.statusCode}');
        print('   Headers: ${response.headers}');
        print('   Body: ${response.body}');
      }
      
      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ API DELETE Error: $e');
        print('   Endpoint: $endpoint');
        print('   Full URL: $url');
        print('   Error Type: ${e.runtimeType}');
      }
      _handleError(e);
      rethrow;
    }
  }

  // Update cart item
  Future<dynamic> updateCartItem({
    required String itemId,
    required int quantity,
    int line = 1,
  }) async {
    if (kDebugMode) {
      print('🛒 Updating cart item:');
      print('   Item ID: $itemId');
      print('   New quantity: $quantity');
      print('   Line: $line');
    }
    
    return post('/api/client/cart/change', {
      'line': line,
      'quantity': quantity,
    });
  }
  
  // Add item to cart
  Future<dynamic> addToCart({
    required dynamic variantId, 
    required int quantity,
    Map<String, dynamic>? properties,
  }) async {
    if (kDebugMode) {
      print('🛒 Adding to cart:');
      print('   Variant ID: $variantId');
      print('   Quantity: $quantity');
      if (properties != null) {
        print('   Properties: $properties');
      }
    }
    
    final Map<String, dynamic> requestBody = {
      'variant_id': (variantId is int) ? variantId : (int.tryParse(variantId.toString()) ?? 1),
      'quantity': quantity,
    };
    
    if (properties != null && properties.isNotEmpty) {
      requestBody['properties'] = properties;
    }
    
    return post('/api/client/cart/add', requestBody);
  }


  void _handleError(dynamic error) {
    print('API Error detail: $error'); // Add more detailed log
    if (kDebugMode) {
      print('API Error: $error');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        // Debug log để kiểm tra response
        if (kDebugMode) {
          print('API Response Body: ${response.body}');
          print('API Response Decoded: ${utf8.decode(response.bodyBytes)}');
        }
        // Đảm bảo giải mã UTF-8 đúng cách
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return {};
    } else {
      _handleHttpError(response);
    }
  }

  void _handleHttpError(http.Response response) {
    if (kDebugMode) {
      print('API Error: ${response.statusCode} - ${response.body}');
    }
    
    switch (response.statusCode) {
      case 401:
        throw Exception('Access denied. Please login again.');
      case 403:
        throw Exception('You do not have permission to access this resource.');
      case 404:
        throw Exception('Requested resource not found.');
      case 500:
      case 502:
      case 503:
      case 504:
        throw Exception('Server error. Please try again later.');
      default:
        try {
          // Đảm bảo giải mã UTF-8 đúng cách khi xử lý lỗi
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          final errorMessage = errorData['message'] ?? 'An unknown error occurred.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('An error occurred: ${response.statusCode}');
        }
    }
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEE8B8B),
        foregroundColor: Colors.white,
        title: const Text('Contact Us'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Hotline
            _buildContactItem(
              icon: Icons.phone,
              title: 'Hotline',
              subtitle: '1900 1234',
              onTap: () => _makePhoneCall('1900 1234'),
            ),
            
            const SizedBox(height: 16),
            
            // Email
            _buildContactItem(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'support@example.com',
              onTap: () => _sendEmail('support@example.com'),
            ),
            
            const SizedBox(height: 16),
            
            // Address
            _buildContactItem(
              icon: Icons.location_on,
              title: 'Address',
              subtitle: '123 ABC Street, XYZ District, Ho Chi Minh City',
              onTap: () => _openMap('123 ABC Street, XYZ District, Ho Chi Minh City'),
            ),
            
            const SizedBox(height: 16),
            
            // Working Hours
            _buildContactItem(
              icon: Icons.access_time,
              title: 'Working Hours',
              subtitle: 'Mon - Fri: 8:00 AM - 5:30 PM\nSat: 8:00 AM - 12:00 PM',
              onTap: null, // Không có hành động khi nhấn vào giờ làm việc
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Card(
      color: Color(0xFFFFF1F1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Color(0xFFFFD6D6),
          child: Icon(icon, color: Color(0xFFEE8B8B)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: onTap != null ? Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  // Mở ứng dụng điện thoại để gọi
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Không thể gọi $phoneNumber';
    }
  }

  // Mở ứng dụng email
  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: encodeQueryParameters(<String, String>{
        'subject': 'Thắc mắc về sản phẩm',
      }),
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Không thể mở email $email';
    }
  }

  // Mở ứng dụng bản đồ
  Future<void> _openMap(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final Uri launchUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Không thể mở bản đồ với địa chỉ $address';
    }
  }

  // Hỗ trợ mã hóa tham số query URL
  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}