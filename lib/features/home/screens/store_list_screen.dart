import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';


class StoreListScreen extends StatefulWidget {
  const StoreListScreen({Key? key}) : super(key: key);

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  String? selectedCity;
  String? selectedDistrict;
  
  // Danh sách các cửa hàng mẫu
  final List<Map<String, String>> stores = [
    {
      'name': 'Cửa hàng Quang Trung',
      'address': '564 Quang Trung',
    },
    {
      'name': 'Cửa hàng Chùa Bộc',
      'address': '133-135',
    },
    {
      'name': 'Cửa hàng Thanh Hóa',
      'address': '233 Lê Hoàn',
    },
    {
      'name': 'Cửa hàng Buôn Ma Thuột',
      'address': '39-41 Quang Trung',
    },
    {
      'name': 'Cửa hàng Nguyễn Thị Thập',
      'address': '603 Nguyễn Thị Thập',
      'tag': '603',
      'tagLabel': 'NGUYỄN THỊ THẬP'
    },
    {
      'name': 'Cửa hàng Hồ Tùng Mậu',
      'address': '63 Hồ Tùng Mậu',
      'tag': '63',
      'tagLabel': 'HỒ TÙNG MẬU'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Chọn chi nhánh'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Chức năng tìm kiếm
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Phần lọc theo thành phố và quận/huyện
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Dropdown Tỉnh/Thành phố
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCity,
                      hint: const Text('Tỉnh/Thành Phố'),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: <String>['Hà Nội', 'TP.HCM', 'Đà Nẵng', 'Cần Thơ']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCity = newValue;
                        });
                      },
                    ),
                  ),
                ),
                // Đường phân cách
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.grey[300],
                ),
                // Dropdown Quận/Huyện
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedDistrict,
                      hint: const Text('Quận/Huyện'),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: <String>['Quận 1', 'Quận 2', 'Quận 3', 'Quận Gò Vấp']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDistrict = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tiêu đề "Cửa hàng gần đây"
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cửa hàng gần đây',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // Danh sách cửa hàng
          Expanded(
            child: ListView.separated(
              itemCount: stores.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final store = stores[index];
                return InkWell(
                  onTap: () {
                    // Trả về cửa hàng đã chọn và đóng màn hình
                    Navigator.of(context).pop(store);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        // Tag (nếu có)
                        if (store['tag'] != null)
                          Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  store['tag']!,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  store['tagLabel']!,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store['name']!,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(store['address']!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}