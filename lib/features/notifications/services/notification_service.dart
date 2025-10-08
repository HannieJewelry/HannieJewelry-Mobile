import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../../../core/services/api_service.dart';
import '../../../features/auth/services/auth_service.dart';

class NotificationService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService? _authService;
  List<NotificationModel> _notifications = [];

  NotificationService({AuthService? authService}) : _authService = authService {
    fetchNotifications();
  }

  List<NotificationModel> get notifications => _notifications;

  int get unreadCount {
    // Return 0 if user is not authenticated
    if (_authService != null && !_authService!.isAuthenticated) {
      return 0;
    }
    return _notifications.where((notification) => !notification.isRead).length;
  }

  Future<void> fetchNotifications() async {
    // Skip fetching if user is not authenticated
    if (_authService != null && !_authService!.isAuthenticated) {
      _notifications = [];
      notifyListeners();
      return;
    }
    
    try {
      final response = await _apiService.get('/api/notifications');
      
      try {
        if (response['code'] == 200 && response['data'] != null) {
          final List<dynamic> notificationsData = response['data'];
          
          _notifications = notificationsData
              .where((notification) => notification != null)
              .map((notification) => NotificationModel.fromMap(notification))
              .toList();
          notifyListeners();
        } else {
          print('Error fetching notifications: ${response['message'] ?? 'Unknown error'}');
          _initializeNotifications();
        }
      } catch (parseError) {
        print('Error parsing notifications data: $parseError');
        _initializeNotifications();
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      // Fallback with sample data if API fails, but only for authenticated users
      if (_authService == null || _authService!.isAuthenticated) {
        _initializeNotifications();
      } else {
        _notifications = [];
        notifyListeners();
      }
    }
  }

  void _initializeNotifications() {
    // Skip sample data if user is not authenticated
    if (_authService != null && !_authService!.isAuthenticated) {
      _notifications = [];
      notifyListeners();
      return;
    }
    
    // Sample data only for authenticated users
    _notifications = [
      NotificationModel(
        id: '1',
        title: 'Special Promotion',
        message: '20% discount on all diamond rings from June 15 to June 30',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.promotion,
        imageUrl: 'assets/images/placeholder.png',
      ),
      // Add other sample notifications if needed
    ];
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    try {
      final response = await _apiService.put('/api/notifications/$id/read', {});
      if (response['code'] == 200) {
        // Update local notification
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index].isRead = true;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking as read: $e');
      // Offline fallback if API fails
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isRead = true;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _apiService.put('/api/notifications/read-all', {});
      if (response['code'] == 200) {
        // Update all local notifications
        for (var notification in _notifications) {
          notification.isRead = true;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error marking all as read: $e');
      // Offline fallback if API fails
      for (var notification in _notifications) {
        notification.isRead = true;
      }
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final response = await _apiService.delete('/api/notifications/$id');
      if (response['code'] == 200) {
        // Remove from local list
        _notifications.removeWhere((n) => n.id == id);
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting notification: $e');
      // Offline fallback if API fails
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final response = await _apiService.delete('/api/notifications/clear');
      if (response['code'] == 200) {
        _notifications.clear();
        notifyListeners();
      }
    } catch (e) {
      print('Error clearing all notifications: $e');
      // Offline fallback if API fails
      _notifications.clear();
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }
}