import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../services/product_service.dart';

class ProductSortDrawer extends StatefulWidget {
  final Function() onClose;
  final Function(String, String) onApplySort;

  const ProductSortDrawer({
    Key? key,
    required this.onClose,
    required this.onApplySort,
  }) : super(key: key);

  @override
  State<ProductSortDrawer> createState() => _ProductSortDrawerState();
}

class _ProductSortDrawerState extends State<ProductSortDrawer> {
  String _selectedSortOption = 'newest';

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Divider(),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _buildSortOption(
                        'newest',
                        'Newest',
                        'createdAt',
                        'DESC',
                      ),
                      Divider(height: 1),
                      _buildSortOption(
                        'bestSelling',
                        'Best Selling',
                        'totalSold',
                        'DESC',
                      ),
                      Divider(height: 1),
                      _buildSortOption(
                        'priceAsc',
                        'Price: Low to High',
                        'variants.price',
                        'ASC',
                      ),
                      Divider(height: 1),
                      _buildSortOption(
                        'priceDesc',
                        'Price: High to Low',
                        'variants.price',
                        'DESC',
                      ),
                    ],
                  ),
                ),
                Divider(),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Sort',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String value, String label, String sortProperty, String direction) {
    final isSelected = _selectedSortOption == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSortOption = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedSortOption = 'newest';
                });
                // Apply reset (newest) sorting immediately
                widget.onApplySort('createdAt', 'DESC');
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                String sortProperty = 'variants.price';
                String direction = '';
                
                switch (_selectedSortOption) {
                  case 'priceAsc':
                    sortProperty = 'variants.price';
                    direction = 'ASC';
                    break;
                  case 'priceDesc':
                    sortProperty = 'variants.price';
                    direction = 'DESC';
                    break;
                  case 'newest':
                    sortProperty = 'createdAt';
                    direction = 'DESC';
                    break;
                  case 'bestSelling':
                    sortProperty = 'totalSold';
                    direction = 'DESC';
                    break;
                }
                
                widget.onApplySort(sortProperty, direction);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
