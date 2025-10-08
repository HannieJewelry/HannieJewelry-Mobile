import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/address_model.dart';
import '../../../features/auth/services/auth_service.dart';

class AddressService extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService? _authService;
  List<Address> _addresses = [];
  Address? _selectedAddress;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  AddressService(this._apiService, {AuthService? authService}) 
      : _authService = authService {
    // Initialize by fetching addresses
    _initializeAddresses();
  }

  // Getters
  List<Address> get addresses => _addresses;
  Address? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get initialized => _initialized;

  // Initialize addresses
  Future<void> _initializeAddresses() async {
    if (_initialized) return;
    await fetchAddresses();
    _initialized = true;
  }

  // Get all addresses
  Future<List<Address>> fetchAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('🔍 AddressService: Fetching addresses');
      }

      final response = await _apiService.get('/api/client/addresses');
      
      if (kDebugMode) {
        print('📋 AddressService: Response received');
        print('   Status code: ${response['code']}');
        print('   Message: ${response['message']}');
      }

      if (response['code'] == 200 && response['data'] != null) {
        final content = response['data']['result']['content'] as List<dynamic>;
        _addresses = content.map((item) => Address.fromMap(item)).toList();
        
        // Set default address as selected if available
        if (_selectedAddress == null && _addresses.isNotEmpty) {
          _selectedAddress = _addresses.firstWhere(
            (address) => address.isDefault,
            orElse: () => _addresses.first,
          );
        }
        
        if (kDebugMode) {
          print('✅ AddressService: Addresses loaded successfully');
          print('   Count: ${_addresses.length}');
        }
      } else {
        // For non-200 responses, just treat as empty data without showing error
        if (kDebugMode) {
          print('⚠️ AddressService: Non-200 response code: ${response['code']}');
          print('   Message: ${response['message']}');
        }
        _addresses = [];
      }
    } catch (e) {
      // Handle server errors silently - just set addresses to empty list
      if (kDebugMode) {
        print('❌ AddressService: Exception while loading addresses');
        print('   Exception: $e');
      }
      _addresses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _addresses;
  }
  
  // Method was previously here for mock addresses but we're removing it
  // We don't want to show mock data in production

  // Select an address
  void selectAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }

  // Add a new address
  Future<Address?> addAddress(Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('🔍 AddressService: Adding new address');
        print('   Address: ${address.toString()}');
      }

      final payload = address.toCreateMap();
      final response = await _apiService.post('/api/client/addresses', payload);
      
      if (kDebugMode) {
        print('📋 AddressService: Response received');
        print('   Status code: ${response['code']}');
        print('   Message: ${response['message']}');
      }

      if ((response['code'] == 200 || response['code'] == 201) && 
          response['data'] != null && 
          response['data']['address'] != null) {
        final newAddress = Address.fromMap(response['data']['address']);
        _addresses.add(newAddress);
        
        // If this is the first address or is marked as default, select it
        if (_addresses.length == 1 || newAddress.isDefault) {
          _selectedAddress = newAddress;
        }
        
        if (kDebugMode) {
          print('✅ AddressService: Address added successfully');
          print('   New address ID: ${newAddress.id}');
        }
        
        notifyListeners();
        return newAddress;
      } else {
        _error = response['message'] ?? 'Failed to add address';
        if (kDebugMode) {
          print('❌ AddressService: Error adding address');
          print('   Error: $_error');
        }
        return null;
      }
    } catch (e) {
      _error = 'Error: $e';
      if (kDebugMode) {
        print('❌ AddressService: Exception while adding address');
        print('   Exception: $e');
      }
      
      // Kiểm tra nếu lỗi là do xác thực (401)
      if (e.toString().contains('Access denied') || e.toString().contains('401')) {
        if (kDebugMode) {
          print('🔄 AddressService: Authentication error detected, attempting to refresh...');
        }
        
        // Nếu có AuthService, thử làm mới token
        if (_authService != null) {
          try {
            if (kDebugMode) {
              print('🔄 AddressService: Attempting to refresh token');
            }
            
            // Khởi tạo lại phiên
            await _authService!.initialize();
            
            // Kiểm tra nếu đã xác thực thành công
            if (_authService!.isAuthenticated) {
              if (kDebugMode) {
                print('✅ AddressService: Authentication refreshed, retrying request');
              }
              
              // Thử lại yêu cầu
              final retryPayload = address.toCreateMap();
              final retryResponse = await _apiService.post('/api/client/addresses', retryPayload);
              
              if ((retryResponse['code'] == 200 || retryResponse['code'] == 201) && 
                  retryResponse['data'] != null && 
                  retryResponse['data']['address'] != null) {
                final newAddress = Address.fromMap(retryResponse['data']['address']);
                _addresses.add(newAddress);
                
                if (_addresses.length == 1 || newAddress.isDefault) {
                  _selectedAddress = newAddress;
                }
                
                notifyListeners();
                return newAddress;
              } else {
                _error = retryResponse['message'] ?? 'Failed to add address after refreshing session';
              }
            } else {
              _error = 'Your login session has expired. Please log in again.';
            }
          } catch (refreshError) {
            _error = 'Cannot refresh login session. Please log in again.';
            if (kDebugMode) {
              print('❌ AddressService: Error refreshing authentication: $refreshError');
            }
          }
        } else {
          _error = 'Your login session has expired. Please log in again.';
        }
      }
      
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update an existing address
  Future<Address?> updateAddress(String id, Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('🔍 AddressService: Updating address');
        print('   ID: $id');
        print('   Address: ${address.toString()}');
      }

      // Use the update map format
      final payload = address.toUpdateMap();
      
      final response = await _apiService.put('/api/client/addresses/$id', payload);
      
      if (kDebugMode) {
        print('📋 AddressService: Response received');
        print('   Status code: ${response['code']}');
        print('   Message: ${response['message']}');
      }

      if (response['code'] == 200 && response['data'] != null) {
        final updatedAddress = Address.fromMap(response['data']['address']);
        
        // Update the address in the list
        final index = _addresses.indexWhere((a) => a.id == id);
        if (index >= 0) {
          _addresses[index] = updatedAddress;
        }
        
        if (kDebugMode) {
          print('✅ AddressService: Address updated successfully');
        }
        
        notifyListeners();
        return updatedAddress;
      } else {
        _error = response['message'] ?? 'Failed to update address';
        if (kDebugMode) {
          print('❌ AddressService: Error updating address');
          print('   Error: $_error');
        }
        return null;
      }
    } catch (e) {
      _error = 'Error: $e';
      if (kDebugMode) {
        print('❌ AddressService: Exception while updating address');
        print('   Exception: $e');
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete an address
  Future<bool> deleteAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('🔍 AddressService: Deleting address');
        print('   ID: $id');
      }

      final response = await _apiService.delete('/api/client/addresses/$id');
      
      if (kDebugMode) {
        print('📋 AddressService: Response received');
        print('   Status code: ${response['code']}');
        print('   Message: ${response['message']}');
      }

      if (response['code'] == 200) {
        // Remove the address from the list
        _addresses.removeWhere((a) => a.id == id);
        
        if (kDebugMode) {
          print('✅ AddressService: Address deleted successfully');
        }
        
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete address';
        if (kDebugMode) {
          print('❌ AddressService: Error deleting address');
          print('   Error: $_error');
        }
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      if (kDebugMode) {
        print('❌ AddressService: Exception while deleting address');
        print('   Exception: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set an address as default
  Future<bool> setDefaultAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('🔍 AddressService: Setting address as default');
        print('   ID: $id');
      }

      final response = await _apiService.put('/api/client/addresses/$id/default', {});
      
      if (kDebugMode) {
        print('📋 AddressService: Response received');
        print('   Status code: ${response['code']}');
        print('   Message: ${response['message']}');
      }

      if (response['code'] == 200) {
        // Update default status in the list
        for (var i = 0; i < _addresses.length; i++) {
          final isDefault = _addresses[i].id == id;
          _addresses[i] = _addresses[i].copyWith(isDefault: isDefault);
        }
        
        if (kDebugMode) {
          print('✅ AddressService: Default address set successfully');
        }
        
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to set default address';
        if (kDebugMode) {
          print('❌ AddressService: Error setting default address');
          print('   Error: $_error');
        }
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      if (kDebugMode) {
        print('❌ AddressService: Exception while setting default address');
        print('   Exception: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
