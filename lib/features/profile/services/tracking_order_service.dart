import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/api_service.dart';
import '../../cart/services/cart_service.dart';
import '../models/tracking_order_model.dart';

class TrackingOrderService extends ChangeNotifier {
  final ApiService _apiService;
  final CartService? _cartService;
  
  List<TrackingOrderModel> _trackingOrders = [];
  bool _isLoading = false;
  String? _error;

  TrackingOrderService(this._apiService, {CartService? cartService}) : _cartService = cartService;

  // Getters
  List<TrackingOrderModel> get trackingOrders => _trackingOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get tracking orders by cart token
  Future<void> fetchTrackingOrders(String cartToken) async {
    _setLoading(true);
    _error = null;
    
    try {
      final response = await _apiService.get(
        '/api/client/orders/tracking?token=$cartToken',
      );

      // ApiService already processes the response, so we get the parsed data directly
      if (response['code'] == 200 && response['data'] != null) {
        final List<dynamic> ordersData = response['data'];
        _trackingOrders = ordersData
            .map((orderMap) => TrackingOrderModel.fromMap(orderMap))
            .toList();
        
        // Sort by created date (newest first)
        _trackingOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _error = null;
      } else {
        _error = response['message'] ?? 'Unable to load order history';
        _trackingOrders = [];
      }
    } catch (e) {
      _error = 'An error occurred: $e';
      _trackingOrders = [];
      debugPrint('Error fetching tracking orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get tracking orders for current user (using JWT authentication)
  Future<void> fetchCurrentUserTrackingOrders() async {
    _setLoading(true);
    _error = null;
    
    try {
      // Use JWT authentication to get user's orders
      final response = await _apiService.get('/api/client/orders/me');
      
      if (response['code'] == 200 && response['data'] != null) {
        final List<dynamic> ordersData = response['data'];
        _trackingOrders = ordersData
            .map((orderMap) => TrackingOrderModel.fromMap(orderMap))
            .toList();
        
        // Sort by created date (newest first)
        _trackingOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _error = null;
      } else {
        _error = response['message'] ?? 'Unable to load order history';
        _trackingOrders = [];
      }
    } catch (e) {
      _error = 'An error occurred: $e';
      _trackingOrders = [];
      debugPrint('Error fetching current user tracking orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh tracking orders
  Future<void> refreshTrackingOrders(String cartToken) async {
    await fetchTrackingOrders(cartToken);
  }

  // Get order by ID
  TrackingOrderModel? getOrderById(String orderId) {
    try {
      return _trackingOrders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  // Get orders by status
  List<TrackingOrderModel> getOrdersByStatus(String status) {
    return _trackingOrders
        .where((order) => order.orderProcessingStatus.toUpperCase() == status.toUpperCase())
        .toList();
  }

  // Get orders by financial status
  List<TrackingOrderModel> getOrdersByFinancialStatus(String status) {
    return _trackingOrders
        .where((order) => order.financialStatus.toUpperCase() == status.toUpperCase())
        .toList();
  }

  // Search orders by order number or order code
  List<TrackingOrderModel> searchOrders(String query) {
    if (query.isEmpty) return _trackingOrders;
    
    final lowercaseQuery = query.toLowerCase();
    return _trackingOrders.where((order) {
      return order.orderNumber.toLowerCase().contains(lowercaseQuery) ||
             order.orderCode.toLowerCase().contains(lowercaseQuery) ||
             order.name.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Clear data
  void clearData() {
    _trackingOrders = [];
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Get status color
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFF9800); // Orange
      case 'CONFIRMED':
        return const Color(0xFF2196F3); // Blue
      case 'PROCESSING':
        return const Color(0xFF9C27B0); // Purple
      case 'SHIPPED':
        return const Color(0xFF00BCD4); // Cyan
      case 'DELIVERED':
        return const Color(0xFF4CAF50); // Green
      case 'CANCELLED':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  // Get financial status color
  static Color getFinancialStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFF9800); // Orange
      case 'PAID':
        return const Color(0xFF4CAF50); // Green
      case 'REFUNDED':
        return const Color(0xFF2196F3); // Blue
      case 'CANCELLED':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF757575); // Grey
    }
  }
}
