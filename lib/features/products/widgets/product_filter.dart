import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/product_category_model.dart';
import '../services/product_service.dart';

// Widget hiệu ứng shimmer đơn giản
class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  _ShimmerEffectState createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: [
                0.0,
                _animation.value.clamp(0.0, 1.0),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProductFilterDrawer extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;
  final Function(ProductCategory)? onCategorySelected;
  final Map<String, dynamic>? initialFilters;

  const ProductFilterDrawer({
    Key? key,
    required this.onApplyFilters,
    this.initialFilters,
    this.onCategorySelected,
  }) : super(key: key);

  @override
  State<ProductFilterDrawer> createState() => _ProductFilterDrawerState();
}

class _ProductFilterDrawerState extends State<ProductFilterDrawer> {
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  String? _selectedVendor;
  String? _selectedProductType;
  ProductCategory? _selectedCategory;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    
    // Sử dụng addPostFrameCallback để tránh gọi API trong quá trình build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFilterOptions();
    });
  }

  Future<void> _loadFilterOptions() async {
    setState(() {
      _isLoading = true;
    });
    
    final productService = Provider.of<ProductService>(context, listen: false);
    
    // Tải dữ liệu song song
    await Future.wait([
      // Tải thông tin lọc
      productService.fetchFilterOptions(),
      
      // Tải danh mục nếu chưa có
      if (productService.categories.isEmpty)
        productService.fetchCategories(),
    ]);
    
    setState(() {
      _isLoading = false;
    });
  }

  void _initializeFilters() {
    if (widget.initialFilters != null) {
      final filters = widget.initialFilters!;

      if (filters.containsKey('minPrice')) {
        _minPriceController.text = filters['minPrice'].toString();
      }

      if (filters.containsKey('maxPrice')) {
        _maxPriceController.text = filters['maxPrice'].toString();
      }

      if (filters.containsKey('vendor')) {
        _selectedVendor = filters['vendor'];
      }

      if (filters.containsKey('productType')) {
        _selectedProductType = filters['productType'];
      }

      if (filters.containsKey('categoryId')) {
        final productService = Provider.of<ProductService>(context, listen: false);
        _selectedCategory = productService.categories.firstWhere(
              (category) => category.id == filters['categoryId'],
          orElse: () => ProductCategory(
            id: '',
            title: 'Unknown',
            handle: '',
            bodyHtml: '',
            itemsCount: 0,
            published: false,
            publishedAt: DateTime.now().toIso8601String(),
            publishedScope: '',
            sortOrder: '',
            updatedAt: DateTime.now().toIso8601String(),
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedVendor = null;
      _selectedProductType = null;
      _selectedCategory = null;
    });
    // Apply empty filters immediately to reload data
    widget.onApplyFilters({});
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};

    if (_minPriceController.text.isNotEmpty) {
      filters['minPrice'] = int.tryParse(_minPriceController.text.replaceAll('.', '')) ?? 0;
    }

    if (_maxPriceController.text.isNotEmpty) {
      filters['maxPrice'] = int.tryParse(_maxPriceController.text.replaceAll('.', '')) ?? 0;
    }

    if (_selectedVendor != null) {
      filters['vendor'] = _selectedVendor;
    }

    if (_selectedProductType != null) {
      filters['productType'] = _selectedProductType;
    }

    if (_selectedCategory != null) {
      if (widget.onCategorySelected != null) {
        // Browse screen behavior - navigate to category tab
        widget.onCategorySelected!(_selectedCategory!);
      } else {
        // Search screen behavior - apply category as filter
        filters['categoryId'] = _selectedCategory!.id;
      }
    }

    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);
    
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPriceRangeSection(),
                        const SizedBox(height: 32),
                        _buildVendorSection(productService),
                        const SizedBox(height: 32),
                        _buildProductTypeSection(productService),
                        const SizedBox(height: 32),
                        _buildProductCategorySection(productService),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildFooterButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Filter',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                decoration: InputDecoration(
                  hintText: 'Minimum',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            const Text('—'),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                decoration: InputDecoration(
                  hintText: 'Maximum',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVendorSection(ProductService productService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Brand',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (productService.isLoadingVendors)
          _buildLoadingChips(3)
        else if (productService.vendors.isEmpty)
          const Center(child: Text('No brand data available'))
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: productService.vendors.map((vendor) {
              final isSelected = vendor['id'] == _selectedVendor;
              return _buildSelectionChip(
                label: vendor['name']!,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedVendor = isSelected ? null : vendor['id'];
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildProductTypeSection(ProductService productService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (productService.isLoadingProductTypes)
          _buildLoadingChips(4)
        else if (productService.productTypes.isEmpty)
          const Center(child: Text('No product type data available'))
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: productService.productTypes.map((type) {
              final isSelected = type['id'] == _selectedProductType;
              return _buildSelectionChip(
                label: type['name']!,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedProductType = isSelected ? null : type['id'];
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildProductCategorySection(ProductService productService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (productService.isLoadingCategories)
          _buildLoadingChips(3)
        else if (productService.categories.isEmpty)
          const Center(child: Text('No category data available'))
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: productService.categories.map((category) {
              final isSelected = category == _selectedCategory;
              return _buildSelectionChip(
                label: category.title,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategory = isSelected ? null : category;
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }
  
  // Widget hiển thị các placeholder loading cho các chip lựa chọn
  Widget _buildLoadingChips(int count) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(count, (index) => _buildLoadingChip()),
    );
  }
  
  Widget _buildLoadingChip() {
    return Container(
      width: 100,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade200,
            Colors.grey.shade300,
          ],
        ),
      ),
      child: const _ShimmerEffect(),
    );
  }
  
  Widget _buildSelectionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetFilters,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reset'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFFF7D7D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}