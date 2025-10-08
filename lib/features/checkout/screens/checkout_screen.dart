
import 'package:demo_v1/features/checkout/screens/qr_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../orders/services/order_service.dart';
import '../../profile/models/address_model.dart';
import '../models/order_model.dart';
import '../services/checkout_service.dart';
import '../widgets/payment_method_modal.dart';
import '../widgets/address_selection_widget.dart';
import 'order_success_screen.dart';
import '../../profile/services/address_service.dart';
import '../../profile/screens/add_address_screen.dart';
import '../../cart/services/cart_service.dart';
import '../../auth/services/auth_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final DeliveryMethod _deliveryMethod = DeliveryMethod.delivery; // Luôn sử dụng phương thức giao hàng
  PaymentMethod _paymentMethod = PaymentMethod.cod;
  Address? _selectedAddress;
  String? _note;
  bool _isLoading = false;
  Map<String, dynamic>? _checkoutData;
  String? _cartToken;
  int? _selectedShippingMethodId;
  int? _selectedPaymentMethodId;
  
  @override
  void initState() {
    super.initState();
    // Get cart token and load checkout data
    _initCheckout();
  }

  Future<void> _initCheckout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load addresses
      await _loadAddresses();
      
      // Fetch checkout data using JWT authentication
      await _fetchCheckoutData();
      
      // Pre-select the first available shipping method that is not "Giao hàng nhanh"
      final checkoutService = Provider.of<CheckoutService>(context, listen: false);
      final allShippingMethods = checkoutService.getShippingMethods(_checkoutData);
      
      // Filter out "Giao hàng nhanh" methods
      final availableShippingMethods = allShippingMethods.where((method) {
        final name = method['name']?.toString().toLowerCase() ?? '';
        return !name.contains('giao hàng nhanh');
      }).toList();
      
      if (availableShippingMethods.isNotEmpty) {
        setState(() {
          final idValue = availableShippingMethods.first['id'];
          _selectedShippingMethodId = idValue is int ? idValue : int.tryParse(idValue.toString());
        });
      } else if (allShippingMethods.isNotEmpty) {
        // Fallback if no filtered methods are available
        setState(() {
          final idValue = allShippingMethods.first['id'];
          _selectedShippingMethodId = idValue is int ? idValue : int.tryParse(idValue.toString());
        });
      }
      
      // Pre-select the first payment method if available
      final paymentMethods = checkoutService.getPaymentMethods(_checkoutData);
      if (paymentMethods.isNotEmpty) {
        setState(() {
          final idValue = paymentMethods.first['id'];
          _selectedPaymentMethodId = idValue is int ? idValue : int.tryParse(idValue.toString());
        });
      }
      
    } catch (e) {
      print('Error initializing checkout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final addressService = Provider.of<AddressService>(context, listen: false);
      await addressService.fetchAddresses();
      
      // Set selected address if available
      if (addressService.selectedAddress != null) {
        setState(() {
          _selectedAddress = addressService.selectedAddress;
        });
      }
    } catch (e) {
      print('Error loading addresses: $e');
    }
  }
  
  Future<void> _fetchCheckoutData() async {
    try {
      final checkoutService = Provider.of<CheckoutService>(context, listen: false);
      final data = await checkoutService.getCheckoutInfo();
      
      if (data != null) {
        setState(() {
          _checkoutData = data;
        });
      }
    } catch (e) {
      print('Error fetching checkout data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load payment information: $e')),
      );
    }
  }

  Future<bool> _updateCheckoutInfo() async {
    if (_selectedAddress == null) return false;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final checkoutService = Provider.of<CheckoutService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Xây dựng thông tin địa chỉ giao hàng
      final shippingAddress = {
        'address': _selectedAddress!.address1,
        'city': _selectedAddress!.city ?? 'Ho Chi Minh',
        'zip_code': _selectedAddress!.zip ?? '70000',
        'company': _selectedAddress!.company ?? '',
        'country_id': 241, // Vietnam
        'province_id': int.tryParse(_selectedAddress!.provinceCode ?? '0') ?? 0,
        'district_id': int.tryParse(_selectedAddress!.districtCode ?? '0') ?? 0,
        'ward_id': int.tryParse(_selectedAddress!.wardCode ?? '0') ?? 0,
      };
      
      // Xây dựng attributes
      final attributes = [
        {'key': 'shipping_instructions', 'value': _note ?? 'No special instructions'}
      ];
      
      // Gọi API để cập nhật checkout
      final updatedData = await checkoutService.updateCheckout(
        addressId: _selectedAddress!.id,
        note: _note,
        shippingMethodId: _selectedShippingMethodId,
        paymentMethodId: _selectedPaymentMethodId,
        attributes: attributes,
      );
      
      if (updatedData != null) {
        setState(() {
          _checkoutData = updatedData;
        });
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(checkoutService.error ?? 'Unable to update payment information')),
        );
        return false;
      }
    } catch (e) {
      print('Error updating checkout data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPaymentMethodModal() {
    // Get cart total from checkout data if available
    final double orderTotal = Provider.of<CheckoutService>(context, listen: false)
        .getTotalPrice(_checkoutData);
        
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PaymentMethodModal(
        onSelect: (method) {
          setState(() {
            _paymentMethod = method;
          });
        },
        orderId: 'temp_order_id', // Temporary ID until we get the actual order ID from the API
        orderTotal: orderTotal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.red.shade300,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // // Delivery method
                  // _buildDeliveryMethodSection(),
                  
                  // Shipping information
                  _buildShippingInfoSection(),
                  
                  // Selected products
                  _buildProductsSection(),
                  
                  // Shipping methods
                  _buildShippingMethodsSection(),
                  
                  // Payment method selection
                  _buildPaymentMethodsSection(),
                  
                  // Order summary
                  _buildOrderSummarySection(),
                  
                  // Notes
                  _buildNotesSection(),
                  
                  // Place order button
                  _buildPlaceOrderButton(),
                ],
              ),
            ),
    );
  }

  
  Widget _buildShippingInfoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),

      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Consignee information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Show address selection as modal bottom sheet
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: Consumer<AddressService>(
                        builder: (context, addressService, child) {
                          return Container(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header with close button
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Select Shipping Address',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: const Icon(
                                          Icons.close,
                                          size: 24,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Address list
                                Flexible(
                                  child: addressService.addresses.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(height: 32),
                                              Icon(
                                                Icons.location_off,
                                                size: 64,
                                                color: Colors.grey.withOpacity(0.5),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No addresses found',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey.withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics: const ClampingScrollPhysics(),
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                          itemCount: addressService.addresses.length,
                                          itemBuilder: (context, index) {
                                            final address = addressService.addresses[index];
                                            final isSelected = addressService.selectedAddress?.id == address.id;
                                            
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isSelected ? const Color(0xFFF78F8E) : Colors.grey.shade200,
                                                  width: 1,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                                color: isSelected ? const Color(0xFFFDF2F1) : Colors.white,
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedAddress = address;
                                                  });
                                                  
                                                  // Update selected address in service
                                                  final addressService = Provider.of<AddressService>(context, listen: false);
                                                  addressService.selectAddress(address);
                                                  
                                                  Navigator.pop(context);
                                                },
                                                borderRadius: BorderRadius.circular(8),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // Radio button
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 2, right: 12),
                                                        child: Container(
                                                          width: 20,
                                                          height: 20,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            border: Border.all(
                                                              color: isSelected ? const Color(0xFFF78F8E) : Colors.grey.shade400,
                                                              width: 1.5,
                                                            ),
                                                            color: Colors.white,
                                                          ),
                                                          child: isSelected
                                                            ? Center(
                                                                child: Container(
                                                                  width: 12,
                                                                  height: 12,
                                                                  decoration: const BoxDecoration(
                                                                    shape: BoxShape.circle,
                                                                    color: Color(0xFFF78F8E),
                                                                  ),
                                                                ),
                                                              )
                                                            : null,
                                                        ),
                                                      ),
                                                      
                                                      // Address details
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  address.fullName,
                                                                  style: const TextStyle(
                                                                    fontWeight: FontWeight.w500,
                                                                    fontSize: 14,
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  '| ${address.phone}',
                                                                  style: TextStyle(
                                                                    color: Colors.grey.shade600,
                                                                    fontSize: 14,
                                                                    fontWeight: FontWeight.normal,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              address.fullAddress,
                                                              style: TextStyle(
                                                                color: Colors.grey.shade600,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                
                                // Add new address button
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                  child: TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddAddressScreen(),
                                        ),
                                      );
                                      // Refresh addresses after returning
                                      if (mounted) {
                                        final addressService = Provider.of<AddressService>(context, listen: false);
                                        addressService.fetchAddresses();
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFFF78F8E),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: const BorderSide(color: Color(0xFFF78F8E)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'Add New Address',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Bottom padding/divider
                                Container(
                                  height: 4,
                                  width: 40,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // const SizedBox(height: 16),
          if (_selectedAddress != null) ...[
            _buildContactInfoItem(Icons.person, _selectedAddress!.fullName),
            _buildContactInfoItem(Icons.phone, _selectedAddress!.phone),
            _buildContactInfoItem(Icons.location_on, _selectedAddress!.fullAddress),
          ] else ...[
            TextButton.icon(
              onPressed: () {
                // Show address selection as modal bottom sheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: Consumer<AddressService>(
                      builder: (context, addressService, child) {
                        return Container(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header with close button
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Select Shipping Address',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: const Icon(
                                        Icons.close,
                                        size: 24,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Address list
                              Flexible(
                                child: addressService.addresses.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(height: 32),
                                            Icon(
                                              Icons.location_off,
                                              size: 64,
                                              color: Colors.grey.withOpacity(0.5),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No addresses found',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey.withOpacity(0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: const ClampingScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                        itemCount: addressService.addresses.length,
                                        itemBuilder: (context, index) {
                                          final address = addressService.addresses[index];
                                          final isSelected = addressService.selectedAddress?.id == address.id;
                                          
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: isSelected ? const Color(0xFFF78F8E) : Colors.grey.shade200,
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                              color: isSelected ? const Color(0xFFFDF2F1) : Colors.white,
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedAddress = address;
                                                });
                                                Navigator.pop(context);
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Radio button
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 2, right: 12),
                                                      child: Container(
                                                        width: 20,
                                                        height: 20,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          border: Border.all(
                                                            color: isSelected ? const Color(0xFFF78F8E) : Colors.grey.shade400,
                                                            width: 1.5,
                                                          ),
                                                          color: Colors.white,
                                                        ),
                                                        child: isSelected
                                                          ? Center(
                                                              child: Container(
                                                                width: 12,
                                                                height: 12,
                                                                decoration: const BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                  color: Color(0xFFF78F8E),
                                                                ),
                                                              ),
                                                            )
                                                          : null,
                                                      ),
                                                    ),
                                                    
                                                    // Address details
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                address.fullName,
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.w500,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                '| ${address.phone}',
                                                                style: TextStyle(
                                                                  color: Colors.grey.shade600,
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.normal,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            address.fullAddress,
                                                            style: TextStyle(
                                                              color: Colors.grey.shade600,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              
                              // Add new address button
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                child: TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddAddressScreen(),
                                      ),
                                    );
                                    // Refresh addresses after returning
                                    if (mounted) {
                                      final addressService = Provider.of<AddressService>(context, listen: false);
                                      addressService.fetchAddresses();
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFFF78F8E),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: const BorderSide(color: Color(0xFFF78F8E)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Add New Address',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Bottom padding/divider
                              Container(
                                height: 4,
                                width: 40,
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add address'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade300,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildContactInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductsSection() {
    final checkoutService = Provider.of<CheckoutService>(context);
    final lineItems = checkoutService.getLineItems(_checkoutData);
    
    if (lineItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'There are no products in the cart.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected products',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...lineItems.map((item) => _buildProductItem(item)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildProductItem(Map<String, dynamic> item) {
    final productTitle = item['product_title'] ?? 'Product';
    final variantTitle = item['variant_title'] ?? '';
    final price = item['price'] ?? 0.0;
    final quantity = item['quantity'] ?? 1;
    final imageUrl = item['image_url'] ?? '';
    final totalPrice = item['line_price'] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/placeholder.png',
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    'assets/images/placeholder.png',
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (variantTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Option: $variantTitle',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatPrice(price)}đ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade400,
                      ),
                    ),
                    Text(
                      'x$quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total: ${_formatPrice(totalPrice)}đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodsSection() {
    final checkoutService = Provider.of<CheckoutService>(context);
    final paymentMethods = checkoutService.getPaymentMethods(_checkoutData);
    
    if (paymentMethods.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      const Text(
              'Payment Method',
              style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...paymentMethods.map((method) => _buildPaymentMethodItem(method)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodItem(Map<String, dynamic> method) {
    final methodId = method['id'];
    final bool isSelected = _selectedPaymentMethodId == methodId;
    final String code = method['code'] ?? '';
    
    // Chọn icon phù hợp cho phương thức thanh toán
    IconData getPaymentIcon(String code) {
      switch (code.toLowerCase()) {
        case 'cod':
          return Icons.money;
        case 'bank_transfer':
          return Icons.account_balance;
        case 'momo':
          return Icons.wallet;
        case 'zalopay':
          return Icons.payment;
        case 'vnpay':
          return Icons.credit_card;
        default:
          return Icons.payment;
      }
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethodId = methodId;
          
          // Nếu đây là phương thức COD, đặt _paymentMethod thành PaymentMethod.cod
          // nếu không thì đặt thành PaymentMethod.bankTransfer
          if (code.toLowerCase() == 'cod') {
            _paymentMethod = PaymentMethod.cod;
          } else {
            _paymentMethod = PaymentMethod.bankTransfer;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.red.shade300 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.red.shade300 : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade300,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(
              getPaymentIcon(code),
              color: Colors.red.shade300,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'] ?? 'Payment method',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (method['description'] != null)
                    Text(
                      method['description'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderSummarySection() {
    final checkoutService = Provider.of<CheckoutService>(context);
    final subtotal = checkoutService.getSubtotal(_checkoutData);
    final discount = checkoutService.getDiscountAmount(_checkoutData);
    
    // Get shipping cost based on selected method
    double shippingCost = 0.0;
    final shippingMethods = checkoutService.getShippingMethods(_checkoutData);
    if (_selectedShippingMethodId != null) {
      for (var method in shippingMethods) {
        if (method['id'] == _selectedShippingMethodId) {
          shippingCost = method['price'] is num ? (method['price'] as num).toDouble() : 0.0;
          break;
        }
      }
    } else {
      shippingCost = checkoutService.getShippingCost(_checkoutData);
    }
    
    // Calculate total with the selected shipping cost
    final totalPrice = checkoutService.calculateTotalWithShipping(_checkoutData, _selectedShippingMethodId);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Checkout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryItem('Provisional', '${_formatPrice(subtotal)}đ'),
          _buildSummaryItem('Shipping fee', '${_formatPrice(shippingCost)}đ'),
          if (discount > 0)
            _buildSummaryItem('Discount', '-${_formatPrice(discount)}đ', isDiscount: true),
          const Divider(height: 24),
          _buildSummaryItem(
            'Total',
            '${_formatPrice(totalPrice)}đ',
            isBold: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, {bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isDiscount ? Colors.green : null,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes (If any)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter note for your order...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
            ),
            maxLines: 3,
            onChanged: (value) {
              setState(() {
                _note = value;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlaceOrderButton() {
    final checkoutService = Provider.of<CheckoutService>(context);
    final totalPrice = checkoutService.calculateTotalWithShipping(_checkoutData, _selectedShippingMethodId);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400,
                ),
              ),
              Text(
                '${_formatPrice(totalPrice)}đ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Order',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }
    
    if (_selectedShippingMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shipping method')),
      );
      return;
    }
    
    if (_selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Get the checkout service and check if data is available
    final checkoutService = Provider.of<CheckoutService>(context, listen: false);
    if (!checkoutService.hasCheckoutData()) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cart information available, please try again.')),
      );
      return;
    }
    
    // Get line items from checkout
    final lineItems = checkoutService.getLineItems(_checkoutData);
    if (lineItems.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }
    
    // Cập nhật thông tin checkout trước khi tạo đơn hàng
    final checkoutUpdated = await _updateCheckoutInfo();
    if (!checkoutUpdated) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update payment information. Please try again.')),
      );
      return;
    }

    try {
      // Hoàn tất đơn hàng bằng API complete checkout
      final result = await checkoutService.completeCheckout();
      
      if (result != null && result['order_id'] != null) {
        final orderId = result['order_id'];
        final orderStatus = result['data']?['status'] ?? 'processing';
        
        // Get the cart service to clear the cart
        final cartService = Provider.of<CartService>(context, listen: false);
        cartService.clear();
        
        // Xác định phương thức thanh toán để điều hướng tới màn hình phù hợp
        String paymentMethodCode = 'cod';
        final paymentMethods = checkoutService.getPaymentMethods(_checkoutData);
        for (var method in paymentMethods) {
          if (method['id'] == _selectedPaymentMethodId) {
            paymentMethodCode = method['code'] ?? 'cod';
            break;
          }
        }
        
        // Determine if the payment method is bank transfer or COD
        bool isBankTransfer = paymentMethodCode.toLowerCase() != 'cod';
        
        if (isBankTransfer) {
          // Đối với thanh toán chuyển khoản, cần đảm bảo đơn hàng đã được xử lý thành công
          if (mounted) {
            // Hiển thị loading và thông báo đang xử lý đơn hàng
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Processing'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Your order is being processed.\nPlease wait a moment...'),
                      const SizedBox(height: 8),
                      Text('Order ID: $orderId', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            );
            
            // Đợi đơn hàng được xử lý (tối đa 5 giây)
            int retryCount = 0;
            const maxRetries = 5;
            bool orderReady = false;
            
            while (retryCount < maxRetries && !orderReady) {
              await Future.delayed(const Duration(seconds: 1));
              
              try {
                // Kiểm tra trạng thái đơn hàng
                final orderService = Provider.of<OrderService>(context, listen: false);
                final orderDetails = await orderService.getOrderById(orderId);
                
                if (orderDetails != null) {
                  orderReady = true;
                }
              } catch (e) {
                print('Đang đợi đơn hàng được xử lý: ${retryCount + 1}/$maxRetries');
                retryCount++;
              }
            }
            
            // Đóng dialog loading
            if (mounted) {
              Navigator.of(context).pop();
            }
            
            // Sau khi đợi, chuyển đến màn hình thanh toán QR
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRPaymentScreen(
                    orderId: orderId,
                    orderTotal: checkoutService.calculateTotalWithShipping(_checkoutData, _selectedShippingMethodId),
                    bankName: 'MBBank',
                    accountNumber: '0914696665',
                    accountName: 'NGUYEN THANH HAU',
                  ),
                ),
              );
            }
          }
        } else {
          // For COD, navigate directly to success screen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderSuccessScreen(
                  orderId: orderId,
                ),
              ),
            );
          }
        }
      } else {
        // Order processing failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to process your order. Please try again.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Helper method to convert dynamic to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  Widget _buildShippingMethodsSection() {
    final checkoutService = Provider.of<CheckoutService>(context);
    
    // Get shipping methods and filter out "Giao hàng nhanh"
    final allShippingMethods = checkoutService.getShippingMethods(_checkoutData);
    final shippingMethods = allShippingMethods.where((method) {
      final name = method['name']?.toString().toLowerCase() ?? '';
      // Filter out methods containing "giao hàng nhanh" in their names
      return !name.contains('giao hàng nhanh');
    }).toList();
    
    if (shippingMethods.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping method',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...shippingMethods.map((method) => _buildShippingMethodItem(method)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildShippingMethodItem(Map<String, dynamic> method) {
    final methodId = method['id'];
    final bool isSelected = _selectedShippingMethodId == methodId;
    final double price = method['price'] is num ? (method['price'] as num).toDouble() : 0.0;
    final String formattedPrice = price > 0 ? '${_formatPrice(price)}đ' : 'Miễn phí';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedShippingMethodId = methodId;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.red.shade300 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.red.shade300 : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade300,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'] ?? 'Phương thức vận chuyển',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (method['description'] != null)
                    Text(
                      method['description'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              formattedPrice,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: price > 0 ? Colors.black : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
