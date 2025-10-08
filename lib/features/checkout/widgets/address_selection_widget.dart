import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../profile/models/address_model.dart';
import '../../profile/services/address_service.dart';
import '../../profile/screens/add_address_screen.dart';
import '../../profile/screens/edit_address_screen.dart';

class AddressSelectionWidget extends StatefulWidget {
  final Function(Address)? onAddressSelected;
  
  const AddressSelectionWidget({
    Key? key,
    this.onAddressSelected,
  }) : super(key: key);

  @override
  State<AddressSelectionWidget> createState() => _AddressSelectionWidgetState();
}

class _AddressSelectionWidgetState extends State<AddressSelectionWidget> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure addresses are loaded
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final addressService = Provider.of<AddressService>(context, listen: false);
    if (addressService.addresses.isEmpty && !addressService.isLoading) {
      setState(() {
        _isLoading = true;
      });
      
      await addressService.fetchAddresses();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressService>(
      builder: (context, addressService, child) {
        final selectedAddress = addressService.selectedAddress;
        final isLoading = _isLoading || addressService.isLoading;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shipping Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAddressSelectionModal(context),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (isLoading) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Loading addresses...'),
                    ],
                  ),
                ),
              ),
            ] else if (selectedAddress != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          selectedAddress.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          selectedAddress.phone,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedAddress.fullAddress,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.red.shade50,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.location_off, color: Colors.red),
                    const SizedBox(height: 8),
                    const Text(
                      'No shipping address selected',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _showAddressSelectionModal(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Select Address'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showAddressSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddressSelectionModal(
            onAddressSelected: (address) {
              final addressService = Provider.of<AddressService>(context, listen: false);
              addressService.selectAddress(address);
              widget.onAddressSelected?.call(address);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}

class AddressSelectionModal extends StatefulWidget {
  final Function(Address) onAddressSelected;
  
  const AddressSelectionModal({
    Key? key,
    required this.onAddressSelected,
  }) : super(key: key);

  @override
  State<AddressSelectionModal> createState() => _AddressSelectionModalState();
}

class _AddressSelectionModalState extends State<AddressSelectionModal> {
  bool _isLoading = false;
  String? _processingAddressId;

  @override
  void initState() {
    super.initState();
    // Refresh addresses when modal is opened
    _refreshAddresses();
  }

  Future<void> _refreshAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final addressService = Provider.of<AddressService>(context, listen: false);
      await addressService.fetchAddresses();
    } catch (e) {
      print('Error refreshing addresses: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setDefaultAddress(Address address) async {
    if (address.isDefault) return;
    
    setState(() {
      _processingAddressId = address.id;
    });
    
    try {
      final addressService = Provider.of<AddressService>(context, listen: false);
      final success = await addressService.setDefaultAddress(address.id);
      
      if (success) {
        await _refreshAddresses();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressService>(
      builder: (context, addressService, child) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : addressService.addresses.isEmpty
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
                              final isProcessing = _processingAddressId == address.id;
                              
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
                                  onTap: () => widget.onAddressSelected(address),
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
                                        
                                        // Edit button
                                        IconButton(
                                          onPressed: () async {
                                            // Navigate to edit address screen
                                            Navigator.pop(context); // Close the modal first
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EditAddressScreen(
                                                  address: address,
                                                ),
                                              ),
                                            );
                                            // Refresh addresses after returning
                                            if (mounted) {
                                              final addressService = Provider.of<AddressService>(context, listen: false);
                                              addressService.fetchAddresses();
                                            }
                                          },
                                          icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              
              // Default tag
              if (!_isLoading && addressService.addresses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      // Fix: remove negative margin
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF78F8E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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
                        builder: (context) => const AddAddressScreen(),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
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
    );
  }
}
