import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';
import 'location_selector_screen.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({Key? key}) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Location data
  LocationModel? _selectedProvince;
  LocationModel? _selectedDistrict;
  LocationModel? _selectedWard;

  bool _isDefault = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Navigate to location selector
  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationSelectorScreen(
          initialType: LocationType.province,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedProvince = result['province'];
        _selectedDistrict = result['district'];
        _selectedWard = result['ward'];
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Address',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Color(0xFFF78F8E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name field
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade500),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red.shade200),
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red.shade200),
                        ),
                        contentPadding: const EdgeInsets.only(left: 16, bottom: 4, top: 8),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Number field
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade500),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red.shade200),
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red.shade200),
                        ),
                        contentPadding: const EdgeInsets.only(left: 16, bottom: 4, top: 8),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location fields (Province/City, District, Ward)
                    const Text(
                      'Province/City',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    TextFormField(
                      readOnly: true,
                      onTap: _selectLocation,
                      decoration: InputDecoration(
                        hintText: 'Select Province/City',
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade500),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red.shade200),
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red.shade200),
                        ),
                        contentPadding: const EdgeInsets.only(left: 16, bottom: 4, top: 8),
                        suffixIcon: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                      controller: TextEditingController(
                        text: _selectedProvince?.name ?? '',
                      ),
                      validator: (value) {
                        if (_selectedProvince == null || _selectedDistrict == null || _selectedWard == null) {
                          return 'Please select your complete location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_selectedProvince != null) ...[
                      const Text(
                        'District',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDistrict?.name ?? '',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_selectedDistrict != null) ...[
                      const Text(
                        'Ward',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedWard?.name ?? '',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],


                    // Detailed address field
                    const Text(
                      'Address Details',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'Enter your detailed address',
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade500),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red.shade200),
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red.shade200),
                        ),
                        contentPadding: const EdgeInsets.only(left: 16, bottom: 4, top: 8),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address details';
                        }
                        return null;
                      },
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Default address toggle
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Set as default address',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          Switch(
                            value: _isDefault,
                            onChanged: (value) {
                              setState(() {
                                _isDefault = value;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF78F8E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 0),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                  ),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: _isLoading ? null : _saveAddress,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Save Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate location selection
    if (_selectedProvince == null || _selectedDistrict == null || _selectedWard == null) {
      setState(() {
        _errorMessage = 'Please select your complete location information';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fullName = _nameController.text.trim();
      final nameParts = fullName.split(' ');

      String firstName = '';
      String lastName = '';

      if (nameParts.length > 1) {
        lastName = nameParts.first;
        firstName = nameParts.sublist(1).join(' ');
      } else if (nameParts.isNotEmpty) {
        firstName = nameParts.first;
      }

      // Create a new address object
      final newAddress = Address(
        id: '',
        firstName: firstName,
        lastName: lastName,
        name: fullName,
        phone: _phoneController.text.trim(),
        address1: _addressController.text.trim(),
        city: _selectedProvince?.name,
        districtCode: _selectedDistrict?.code,
        provinceCode: _selectedProvince?.code,
        wardCode: _selectedWard?.code,
        isDefault: false, // Always set to false initially
      );

      // Save the address using the service
      final addressService = Provider.of<AddressService>(context, listen: false);
      final result = await addressService.addAddress(newAddress);

      if (result != null) {
        // If user wants to set as default, make an additional API call
        if (_isDefault) {
          final defaultResult = await addressService.setDefaultAddress(result.id);
          if (!defaultResult) {
            // Show warning but don't fail the whole operation
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Address created but failed to set as default'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
        
        if (mounted) {
          Navigator.pop(context, true); // Return success
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = addressService.error ?? 'Failed to save address. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }
}