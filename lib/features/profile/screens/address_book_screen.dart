import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';
import 'add_address_screen.dart';
import 'edit_address_screen.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  bool _isLoading = true;
  String? _processingAddressId;
  
  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }
  
  Future<void> _loadAddresses() async {
    final addressService = Provider.of<AddressService>(context, listen: false);
    await addressService.fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chọn địa chỉ nhận hàng',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AddressService>(
        builder: (context, addressService, child) {
          if (addressService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final addresses = addressService.addresses;
          
          return Column(
            children: [
              // Removed the Add New Address button from here
              Expanded(
                child: addresses.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có địa chỉ nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAddresses,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(0),
                          itemCount: addresses.length + 1, // +1 for add button
                          itemBuilder: (context, index) {
                            if (index == addresses.length) {
                              return _buildAddButton();
                            }
                            final address = addresses[index];
                            return _buildAddressCard(address, index);
                          },
                        ),
                      ),
              ),
              // Confirm button at bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Return selected address
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Xác nhận'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(Address address, int index) {
    final addressService = Provider.of<AddressService>(context, listen: false);
    final isSelected = addressService.selectedAddress?.id == address.id;
    
    return InkWell(
      onTap: () {
        addressService.selectAddress(address);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  width: 2,
                ),
                color: Colors.white,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Address details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${address.fullName} - ${address.phone}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (address.isDefault)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Mặc định',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Edit button
            TextButton(
              onPressed: () => _editAddress(address),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text(
                'Sửa',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _addNewAddress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: AppColors.primary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Thêm địa chỉ mới',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setDefaultAddress(Address address) async {
    if (address.isDefault) return;
    
    setState(() {
      _processingAddressId = address.id;
    });
    
    try {
      final addressService = Provider.of<AddressService>(context, listen: false);
      final primary = await addressService.setDefaultAddress(address.id);
      
      if (primary) {
        await _loadAddresses();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Default address updated primaryfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(addressService.error ?? 'Failed to update default address'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingAddressId = null;
        });
      }
    }
  }
  
  Future<void> _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAddressScreen(),
      ),
    );
    
    // Refresh the list after adding a new address
    if (result == true) {
      _loadAddresses();
    }
  }
  
  Future<void> _editAddress(Address address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAddressScreen(address: address),
      ),
    );
    
    // Refresh the list after editing an address
    if (result == true) {
      _loadAddresses();
    }
  }
}