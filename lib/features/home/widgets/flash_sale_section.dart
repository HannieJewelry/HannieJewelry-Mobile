import 'package:flutter/material.dart';

class FlashSaleSection extends StatelessWidget {
  const FlashSaleSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🔥 Dữ liệu Flash Sale dạng object
    final List<Map<String, dynamic>> flashSaleProducts = [
      {
        "image": "https://cloud.huythanhjewelry.vn/storage/photos/shares/01upload/1753254211/ndino343movt1_1753279105.png",
        "price": "60.000₫",
        "discount": "44%",
      },
      {
        "image": "https://cloud.huythanhjewelry.vn/storage/photos/shares/01upload/1753253999/ndino341movt1_1753275304.png",
        "price": "69.000₫",
        "discount": "44%",
      },
      {
        "image": "https://cdn.huythanhjewelry.vn/storage/rs300/shares/01upload/1731752851/ndino324movt1_1731894075.png.webp",
        "price": "70.000₫",
        "discount": "50%",
      },
      {
        "image": "https://cdn.huythanhjewelry.vn/storage/rs300/shares/01upload/1731752851/ndino324movt1_1731894075.png.webp",
        "price": "45.000₫",
        "discount": "60%",
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.redAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // 🔥 Header Flash Sale
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'FLASH Sale',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '02:52:48', // ✅ Có thể thay bằng countdown sau này
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SĂN NGAY >',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 🔥 Danh sách sản phẩm Flash Sale
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: flashSaleProducts.length,
              itemBuilder: (context, index) {
                final product = flashSaleProducts[index];

                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(8)),
                          child: Image.network(
                            product["image"],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          children: [
                            Text(
                              product["price"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product["discount"],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
