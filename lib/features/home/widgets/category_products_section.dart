import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../products/models/product_category_model.dart';
import '../../products/models/product_model.dart';
import '../../products/services/product_service.dart';
import 'product_card.dart';

class CategoryProductsSection extends StatelessWidget {
  final Map<String, List<Product>> categoryProductsCache;
  final String? currentCategoryHandle;
  final Function(ProductCategory, ProductService) onCategorySwitch;

  const CategoryProductsSection({
    Key? key,
    required this.categoryProductsCache,
    required this.currentCategoryHandle,
    required this.onCategorySwitch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductService>(
      builder: (context, productService, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'FOR YOU',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.PRODUCT_BROWSE);
                    },
                    child: const Text(
                      'View All >',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Category tabs
              if (productService.categories.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: productService.categories.length,
                    itemBuilder: (context, index) {
                      final category = productService.categories[index];
                      final isSelected = productService.selectedCategory?.id == category.id;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            onCategorySwitch(category, productService);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              category.title,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              // 2-column grid that expands to show all products
              _buildCategoryProducts(productService),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryProducts(ProductService productService) {
    final categoryHandle = currentCategoryHandle ?? productService.selectedCategory?.handle;

    if (categoryHandle == null) {
      return _buildSampleForYouGrid();
    }

    final cachedProducts = categoryProductsCache[categoryHandle];
    final products = cachedProducts ?? productService.products;

    if (products.isEmpty) {
      if (productService.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return _buildSampleForYouGrid();
    }

    return GridView.builder(
      shrinkWrap: true, // Allow GridView to size itself based on content
      physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling to use parent scroll
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8, // Adjusted for better mobile display
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(product: product);
      },
    );
  }

  Widget _buildSampleForYouGrid() {
    // Sample data for "For You" section when no products are available
    final sampleProducts = List.generate(6, (index) => {
      'title': 'Sample Product ${index + 1}',
      'price': '${(index + 1) * 100}.000₫',
      'image': 'assets/images/placeholder.png',
    });

    return GridView.builder(
      shrinkWrap: true, // Allow GridView to size itself based on content
      physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling to use parent scroll
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: sampleProducts.length,
      itemBuilder: (context, index) {
        final product = sampleProducts[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.asset(
                    product['image']!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['title']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['price']!,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
