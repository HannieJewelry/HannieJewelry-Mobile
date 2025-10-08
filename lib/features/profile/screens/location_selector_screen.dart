import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/api_service.dart';
import '../../../core/constants/app_colors.dart';

enum LocationType {
  province,
  district,
  ward,
}

class LocationModel {
  final int id;
  final String name;
  final String? code;

  LocationModel({
    required this.id,
    required this.name,
    this.code,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      code: map['code'],
    );
  }
}

class LocationSelectorScreen extends StatefulWidget {
  final LocationType initialType;
  final int? provinceId;
  final int? districtId;

  const LocationSelectorScreen({
    Key? key,
    this.initialType = LocationType.province,
    this.provinceId,
    this.districtId,
  }) : super(key: key);

  @override
  State<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends State<LocationSelectorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<LocationModel> _provinces = [];
  List<LocationModel> _districts = [];
  List<LocationModel> _wards = [];
  
  List<LocationModel> _filteredProvinces = [];
  List<LocationModel> _filteredDistricts = [];
  List<LocationModel> _filteredWards = [];
  
  bool _loadingProvinces = true;
  bool _loadingDistricts = false;
  bool _loadingWards = false;
  
  String? _error;

  // Selected locations for displaying
  LocationModel? _selectedProvince;
  LocationModel? _selectedDistrict;
  LocationModel? _selectedWard;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: widget.initialType.index,
    );
    
    _tabController.addListener(() {
      _searchController.clear();
      _updateFilteredList();
    });
    
    _fetchProvinces();
    
    if (widget.provinceId != null) {
      _fetchDistricts(widget.provinceId!);
      
      if (widget.districtId != null) {
        _fetchWards(widget.districtId!);
      }
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchProvinces() async {
    setState(() {
      _loadingProvinces = true;
      _error = null;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get('/api/countries/241/provinces');
      
      if (response['code'] == 200) {
        final data = response['data'];
        final country = data['country'];
        final provinces = List<Map<String, dynamic>>.from(country['provinces']);
        
        setState(() {
          _provinces = provinces.map((p) => LocationModel.fromMap(p)).toList();
          _filteredProvinces = List.from(_provinces);
          _loadingProvinces = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load provinces';
          _loadingProvinces = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loadingProvinces = false;
      });
    }
  }
  
  Future<void> _fetchDistricts(int provinceId) async {
    setState(() {
      _loadingDistricts = true;
      _error = null;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get('/api/districts?province_id=$provinceId');
      
      if (response['code'] == 200) {
        final data = response['data'];
        final districts = List<Map<String, dynamic>>.from(data['districts']);
        
        setState(() {
          _districts = districts.map((d) => LocationModel.fromMap(d)).toList();
          _filteredDistricts = List.from(_districts);
          _loadingDistricts = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load districts';
          _loadingDistricts = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loadingDistricts = false;
      });
    }
  }
  
  Future<void> _fetchWards(int districtId) async {
    setState(() {
      _loadingWards = true;
      _error = null;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get('/api/wards?district_id=$districtId');
      
      if (response['code'] == 200) {
        final data = response['data'];
        final wards = List<Map<String, dynamic>>.from(data['wards']);
        
        setState(() {
          _wards = wards.map((w) {
            // Convert ward data format to match our model
            return LocationModel(
              id: int.tryParse(w['code'] ?? '0') ?? 0,
              name: w['name'] ?? '',
              code: w['code'],
            );
          }).toList();
          _filteredWards = List.from(_wards);
          _loadingWards = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load wards';
          _loadingWards = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loadingWards = false;
      });
    }
  }
  
  void _updateFilteredList() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      switch (_tabController.index) {
        case 0: // Province
          _filteredProvinces = _provinces.where(
            (province) => province.name.toLowerCase().contains(query)
          ).toList();
          break;
        case 1: // District
          _filteredDistricts = _districts.where(
            (district) => district.name.toLowerCase().contains(query)
          ).toList();
          break;
        case 2: // Ward
          _filteredWards = _wards.where(
            (ward) => ward.name.toLowerCase().contains(query)
          ).toList();
          break;
      }
    });
  }
  
  void _onProvinceSelected(LocationModel province) {
    setState(() {
      _selectedProvince = province;
    });
    _fetchDistricts(province.id);
    _tabController.animateTo(1); // Move to district tab
  }
  
  void _onDistrictSelected(LocationModel district) {
    setState(() {
      _selectedDistrict = district;
    });
    _fetchWards(district.id);
    _tabController.animateTo(2); // Move to ward tab
  }
  
  void _onWardSelected(LocationModel ward) {
    setState(() {
      _selectedWard = ward;
    });
    
    // Return the selected locations to the previous screen
    Navigator.pop(context, {
      'province': _selectedProvince,
      'district': _selectedDistrict,
      'ward': ward,
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select address',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Province, City'),
            Tab(text: 'District'),
            Tab(text: 'Ward, Commune'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search field
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(32),
            ),
            // child: Row(
            //   children: [
            //     Icon(Icons.search, color: Colors.grey.shade600),
            //     const SizedBox(width: 8),
            //     Expanded(
            //       child: TextField(
            //         controller: _searchController,
            //         decoration: InputDecoration(
            //           hintText: _tabController.index == 0
            //               ? 'Search Province/City'
            //               : _tabController.index == 1
            //                   ? 'Search District'
            //                   : 'Search Ward',
            //           border: InputBorder.none,
            //           hintStyle: TextStyle(color: Colors.grey.shade500),
            //         ),
            //         onChanged: (value) => _updateFilteredList(),
            //       ),
            //     ),
            //     if (_searchController.text.isNotEmpty)
            //       IconButton(
            //         icon: const Icon(Icons.clear, color: Colors.black),
            //         onPressed: () {
            //           _searchController.clear();
            //           _updateFilteredList();
            //         },
            //       ),
            //     IconButton(
            //       icon: const Icon(Icons.search, color: Colors.black),
            //       onPressed: () => _updateFilteredList(),
            //     ),
            //   ],
            // ),
          ),

          // Location lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Province list
                _buildLocationList(
                  items: _filteredProvinces,
                  loading: _loadingProvinces,
                  onItemTap: _onProvinceSelected,
                ),

                // District list
                _buildLocationList(
                  items: _filteredDistricts,
                  loading: _loadingDistricts,
                  onItemTap: _onDistrictSelected,
                ),

                // Ward list
                _buildLocationList(
                  items: _filteredWards,
                  loading: _loadingWards,
                  onItemTap: _onWardSelected,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationList({
    required List<LocationModel> items,
    required bool loading,
    required Function(LocationModel) onItemTap,
  }) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Cannot load data',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                switch (_tabController.index) {
                  case 0:
                    _fetchProvinces();
                    break;
                  case 1:
                    if (widget.provinceId != null) {
                      _fetchDistricts(widget.provinceId!);
                    }
                    break;
                  case 2:
                    if (widget.districtId != null) {
                      _fetchWards(widget.districtId!);
                    }
                    break;
                }
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    if (items.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isNotEmpty 
              ? 'No matching address found' 
              : 'No address found',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(
            item.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          onTap: () => onItemTap(item),
        );
      },
    );
  }
} 