import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/profile_model.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../features/auth/models/user_model.dart';

class ProfileService extends ChangeNotifier {
  final AuthService _authService;
  final ApiService _apiService;
  
  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileService(this._authService, this._apiService);

  // Getters
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // GET Profile - /api/client/customers/profile
  Future<Profile?> getProfile({int retryCount = 0}) async {
    if (!_authService.isAuthenticated) {
      _error = 'User not authenticated';
      print('❌ ProfileService: User not authenticated');
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    if (kDebugMode) {
      print('🔍 ProfileService: Starting getProfile()');
      print('   Auth Status: ${_authService.isAuthenticated}');
      print('   Current User: ${_authService.currentUser?.name ?? 'None'}');
    }

    try {
      final response = await _apiService.get('/api/client/customers/profile');
      
      if (kDebugMode) {
        print('📋 ProfileService: GET Profile Response:');
        print('   Full Response: $response');
        print('   Response Type: ${response.runtimeType}');
        print('   Has Code: ${response.containsKey('code')}');
        print('   Code Value: ${response['code']}');
        print('   Has Data: ${response.containsKey('data')}');
        print('   Data: ${response['data']}');
      }
      
      // Handle both response structures: {success: true} and {code: 200}
      bool isSuccess = (response['success'] == true) || (response['code'] == 200);
      bool hasCustomerData = response['data'] != null && response['data']['customer'] != null;
      
      if (isSuccess && hasCustomerData) {
        _profile = Profile.fromMap(response['data']['customer']);
        _error = null;
        if (kDebugMode) {
          print('✅ ProfileService: Profile loaded successfully');
          print('   Profile: ${_profile?.displayName}');
          print('   Profile Full Name: ${_profile?.fullName}');
          print('   Profile Email: ${_profile?.email}');
          print('   Profile Phone: ${_profile?.phone}');
          print('   Profile Gender: ${_profile?.gender}');
          print('   Profile ID: ${_profile?.id}');
        }
        notifyListeners();
        return _profile;
      } else {
        // Handle server errors more gracefully
        _error = response['message'] ?? 'Cannot load personal information';
        print('❌ ProfileService: Error fetching profile');
        print('   Success: ${response['success']}');
        print('   Code: ${response['code']}');
        print('   Error Message: ${response['message']}');
        print('   Has Customer Data: $hasCustomerData');
        print('   Full Response: $response');
        notifyListeners();
        return null;
      }
    } catch (e) {
      // Retry logic for server errors
      if (retryCount < 2 && (e.toString().contains('Server error') || e.toString().contains('500'))) {
        print('🔄 ProfileService: Retrying getProfile (attempt ${retryCount + 1}/3)');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2)); // Progressive delay
        return getProfile(retryCount: retryCount + 1);
      }
      
      // Improve error messages for users
      if (e.toString().contains('Server error') || e.toString().contains('500')) {
        _error = 'Server is under maintenance, please try again later';
      } else if (e.toString().contains('Connection')) {
        _error = 'No network connection, please check and try again';
      } else {
        _error = 'An error occurred, please try again later';
      }
      print('❌ ProfileService: Exception in getProfile()');
      print('   Exception: $e');
      print('   Exception Type: ${e.runtimeType}');
      if (e is Exception) {
        print('   Exception String: ${e.toString()}');
      }
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('🏁 ProfileService: getProfile() completed');
      }
    }
  }

  // PUT Profile - /api/client/customers/profile (form-data)
  Future<Profile?> updateProfile({
    String? email,
    String? firstName,
    String? lastName,
    String? birthday,
    String? gender,
    File? avatarFile,
  }) async {
    if (kDebugMode) {
      print('🔄 ProfileService: Starting updateProfile()');
      print('   Email: $email');
      print('   FirstName: $firstName');
      print('   LastName: $lastName');
      print('   Birthday: $birthday');
      print('   Gender: $gender');
      print('   Avatar: ${avatarFile != null ? 'Yes' : 'No'}');
      print('   Auth Status: ${_authService.isAuthenticated}');
    }

    if (!_authService.isAuthenticated) {
      _error = 'User not authenticated';
      print('❌ ProfileService: User not authenticated');
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create multipart request for form-data (always use form-data)
      final uri = Uri.parse('${_apiService.baseUrl}/api/client/customers/profile');
      final request = http.MultipartRequest('PUT', uri);
      
      if (kDebugMode) {
        print('🌐 ProfileService: Creating PUT request with form-data');
        print('   URL: $uri');
        print('   Base URL: ${_apiService.baseUrl}');
      }
      
      // Add headers (keep Authorization, remove only Content-Type for multipart)
      final headers = Map<String, String>.from(_apiService.headers);
      headers.remove('Content-Type'); // Remove only Content-Type, keep Authorization
      request.headers.addAll(headers);
      
      if (kDebugMode) {
        print('   Headers: ${request.headers}');
        print('   Authorization: ${headers.containsKey('Authorization') ? 'Present' : 'Missing'}');
      }
      
      // Add form fields
      if (email != null) request.fields['email'] = email;
      if (firstName != null) request.fields['firstName'] = firstName;
      if (lastName != null) request.fields['lastName'] = lastName;
      if (birthday != null) {
        // Convert birthday to ISO format if needed
        String formattedBirthday = birthday;
        try {
          // Kiểm tra và sửa định dạng năm không hợp lệ (như 102-10-01)
          if (birthday.contains('-')) {
            final parts = birthday.split('-');
            if (parts.length == 3) {
              int year = int.tryParse(parts[0]) ?? 0;
              // Nếu năm < 1000, giả định là năm 2000+
              if (year < 1000) {
                if (year < 100) {
                  year = 2000 + year;
                } else {
                  year = 1900 + year;
                }
                formattedBirthday = '$year-${parts[1]}-${parts[2]}';
              }
            }
          }
          
          // Chuyển đổi sang định dạng ISO nhưng giữ nguyên ngày (không dùng UTC)
          // Thêm giờ là 12:00:00 để tránh vấn đề múi giờ
          final date = DateTime.parse(formattedBirthday);
          formattedBirthday = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T12:00:00.000Z';
          
          if (kDebugMode) {
            print('   Birthday Converted: $birthday → $formattedBirthday');
          }
        } catch (e) {
          print('⚠️ ProfileService: Warning - could not parse birthday: $birthday');
          print('⚠️ ProfileService: Error details: $e');
          // Sử dụng ngày mặc định nếu không thể phân tích
          try {
            final defaultDate = DateTime(2000, 1, 1);
            formattedBirthday = '${defaultDate.year}-${defaultDate.month.toString().padLeft(2, '0')}-${defaultDate.day.toString().padLeft(2, '0')}T12:00:00.000Z';
            print('⚠️ ProfileService: Using default date: $formattedBirthday');
          } catch (e) {
            formattedBirthday = '2000-01-01T12:00:00.000Z';
          }
        }
        request.fields['birthday'] = formattedBirthday;
      }
      if (gender != null) request.fields['gender'] = gender;
      
      if (kDebugMode) {
        print('   Form Fields: ${request.fields}');
      }
      
      // Add avatar file if provided
      if (avatarFile != null) {
        final avatarMultipart = await http.MultipartFile.fromPath(
          'avatar',
          avatarFile.path,
        );
        request.files.add(avatarMultipart);
        if (kDebugMode) {
          print('   Avatar file added: ${avatarFile.path}');
        }
      }
      
      if (kDebugMode) {
        print('📤 ProfileService: Sending PUT form-data request...');
      }
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (kDebugMode) {
        print('📥 ProfileService: PUT Response received');
        print('   Status Code: ${response.statusCode}');
        print('   Response Headers: ${response.headers}');
        print('   Response Body: ${response.body}');
      }
      
      // Process response
      Map<String, dynamic> responseData = {};
      
      // Handle empty response body
      if (response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          print('❌ ProfileService: Failed to decode response body');
          print('   Response Body: "${response.body}"');
          print('   Decode Error: $e');
          _error = 'Invalid response format from server';
          notifyListeners();
          return null;
        }
      } else {
        print('❌ ProfileService: Empty response body');
        if (response.statusCode == 401) {
          _error = 'Authentication failed. Please login again.';
        } else {
          _error = 'Server returned empty response (Status: ${response.statusCode})';
        }
        notifyListeners();
        return null;
      }
      
      if (response.statusCode == 200 && responseData['code'] == 200) {
        if (responseData['data'] != null && responseData['data']['customer'] != null) {
          // Create Profile from the complete response structure
          _profile = Profile.fromMap(responseData);
          
          // Also update the User in AuthService if available
          if (_authService.isAuthenticated) {
            final user = User.fromMap(responseData);
            _authService.updateCurrentUser(user);
            
            if (kDebugMode) {
              print('✅ ProfileService: Updated both Profile and AuthService User');
              print('   Profile ID: ${_profile?.id}');
              print('   User Name: ${user.name}');
            }
          }
        }
        _error = null;
        notifyListeners();
        return _profile;
      } else {
        _error = responseData['message'] ?? 'Failed to update profile';
        print('❌ ProfileService: Error updating profile');
        print('   Error Code: ${responseData['code']}');
        print('   Error Message: ${responseData['message']}');
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error when updating profile: $e';
      print('❌ ProfileService: Exception in updateProfile()');
      print('   Exception: $e');
      print('   Exception Type: ${e.runtimeType}');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('🏁 ProfileService: updateProfile() completed');
      }
    }
  }

  // Update profile with Profile object
  Future<Profile?> updateProfileFromObject(Profile profile, {File? avatarFile}) async {
    return await updateProfile(
      email: profile.email,
      firstName: profile.firstName,
      lastName: profile.lastName,
      birthday: profile.birthday,
      gender: profile.gender,
      avatarFile: avatarFile,
    );
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear profile data
  void clearProfile() {
    _profile = null;
    _error = null;
    notifyListeners();
  }
}
