import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';
import 'location_selector_screen.dart';

class EditAddressScreen extends StatefulWidget {
  final Address address;
  
  const EditAddressScreen({Key? key, required this.address}) : super(key: key);

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  
  // Location data
  LocationModel? _selectedProvince;
  LocationModel? _selectedDistrict;
  LocationModel? _selectedWard;
  
  late bool _isDefault;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: '${widget.address.firstName} ${widget.address.lastName}');
    _phoneController = TextEditingController(text: widget.address.phone);
    _addressController = TextEditingController(text: widget.address.address1);
    
    // Initialize with location data
    _loadLocationData();
    
    // Check if address is default
    _isDefault = widget.address.isDefault;
  }

  Future<void> _loadLocationData() async {
    try {
      if (widget.address.provinceCode != null) {
        final apiService = Provider.of<ApiService>(context, listen: false);
        
        // Load province data
        final provincesResponse = await apiService.get('/api/countries/241/provinces');
        if (provincesResponse['code'] == 200) {
          final data = provincesResponse['data'];
          final country = data['country'];
          final provinces = List<Map<String, dynamic>>.from(country['provinces']);
          
          // Find the matching province
          final provinceData = provinces.firstWhere(
            (p) => p['code'] == widget.address.provinceCode,
            orElse: () => {'id': 0, 'name': widget.address.city ?? 'Unknown', 'code': widget.address.provinceCode}
          );
          
          _selectedProvince = LocationModel.fromMap(provinceData);
          
          // Load district data if we have a province
          if (_selectedProvince != null && widget.address.districtCode != null) {
            final districtsResponse = await apiService.get('/api/districts?province_id=${_selectedProvince!.id}');
            if (districtsResponse['code'] == 200) {
              final data = districtsResponse['data'];
              final districts = List<Map<String, dynamic>>.from(data['districts']);
              
              // Find the matching district
              final districtData = districts.firstWhere(
                (d) => d['code'] == widget.address.districtCode,
                orElse: () => {'id': 0, 'name': 'District', 'code': widget.address.districtCode}
              );
              
              _selectedDistrict = LocationModel.fromMap(districtData);
              
              // Load ward data if we have a district
              if (_selectedDistrict != null && widget.address.wardCode != null) {
                final wardsResponse = await apiService.get('/api/wards?district_id=${_selectedDistrict!.id}');
                if (wardsResponse['code'] == 200) {
                  final data = wardsResponse['data'];
                  final wards = List<Map<String, dynamic>>.from(data['wards']);
                  
                  // Find the matching ward
                  final wardData = wards.firstWhere(
                    (w) => w['code'] == widget.address.wardCode,
                    orElse: () => {'code': widget.address.wardCode ?? '0', 'name': 'Ward'}
                  );
                  
                  _selectedWard = LocationModel(
                    id: int.tryParse(wardData['code'] ?? '0') ?? 0,
                    name: wardData['name'] ?? 'Ward',
                    code: wardData['code'],
                  );
                }
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading location data: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Add method to navigate to location selector
  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => LocationSelectorScreen(
          initialType: LocationType.province,
          provinceId: _selectedProvince?.id,
          districtId: _selectedDistrict?.id,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Address',
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
      body: _isInitializing 
      ? const Center(child: CircularProgressIndicator())
      : Form(
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
                    InkWell(
                  onTap: _selectLocation,
                      child: Container(
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
                              _selectedProvince?.name ?? 'Select Province/City',
                              style: TextStyle(
                                color: _selectedProvince != null 
                                    ? Colors.black 
                                    : Colors.grey.shade600,
                                  ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                    ),
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
                    
                    if (_selectedProvince == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Please select your location',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              
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
                    
                    const SizedBox(height: 16),
                    
                    // Delete button
                    Align(
                      alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _confirmDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          backgroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                          ),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: const Text('Delete Address'),
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
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 0),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                  ),
                    )
                  : const Text('Save Changes'),
          ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    // Validate form and location selection
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
      // Split full name into first name and last name
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
      
        // Create updated address object
        final updatedAddress = Address(
          id: widget.address.id,
        firstName: firstName,
        lastName: lastName,
        name: fullName,
          phone: _phoneController.text.trim(),
        address1: _addressController.text.trim(),
        address2: widget.address.address2,
        city: _selectedProvince?.name,
        company: widget.address.company,
          countryCode: widget.address.countryCode ?? 'VN',
        districtCode: _selectedDistrict?.code,
        provinceCode: _selectedProvince?.code,
        wardCode: _selectedWard?.code,
        zip: widget.address.zip,
        isDefault: _isDefault,
        );
        
        // Save the address using the service
        final addressService = Provider.of<AddressService>(context, listen: false);
        final result = await addressService.updateAddress(widget.address.id, updatedAddress);
        
        if (result != null) {
          // If the default status has changed, make a separate API call to set it as default
          if (_isDefault && !widget.address.isDefault) {
            await addressService.setDefaultAddress(widget.address.id);
          }
          
          if (mounted) {
            Navigator.pop(context, true); // Return success
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = addressService.error ?? 'Failed to update address. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _confirmDelete() async {
    // Show confirmation dialog for deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        final addressService = Provider.of<AddressService>(context, listen: false);
        final success = await addressService.deleteAddress(widget.address.id);
        
        if (success && mounted) {
          Navigator.pop(context, true); // Return success
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = addressService.error ?? 'Failed to delete address. Please try again.';
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
}