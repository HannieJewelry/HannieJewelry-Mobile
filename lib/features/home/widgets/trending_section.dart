import 'package:flutter/material.dart';

class TrendingSection extends StatelessWidget {
  const TrendingSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> trendingProducts = [
      {
        "image":
            "https://cdn.huythanhjewelry.vn/storage/photos/shares/01upload/1731752863/ndino330ldia-vt-1_1732009337.png",
        "price": "142.000₫",
        "originalPrice": "280.000₫",
        "discount": "40%",
      },
      {
        "image":
            "https://cdn.huythanhjewelry.vn/storage/photos/shares/01upload/1750065503900/nlf417bac9251_1750069657.jpg",
        "price": "290.000₫",
        "originalPrice": "580.000₫",
        "discount": "50%",
      },
      {
        "image":
            "https://cdn.huythanhjewelry.vn/storage/photos/shares/01upload/1731752863/ndino330ldia-vt-1_1732009337.png",
        "price": "219.000₫",
        "originalPrice": "440.000₫",
        "discount": "50%",
      },
      {
        "image":
            "https://cdn.huythanhjewelry.vn/storage/photos/shares/01upload/1750065503900/nlf417bac9251_1750069657.jpg",
        "price": "800.000₫",
        "originalPrice": "1.600.000₫",
        "discount": "50%",
      },
      {
        "image":
            "https://cdn.huythanhjewelry.vn/storage/photos/shares/01upload/1750065503900/nlf417bac9251_1750069657.jpg",
        "price": "1.200.000₫",
        "originalPrice": "2.400.000₫",
        "discount": "50%",
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'TRENDING',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
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
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: trendingProducts.length,
              itemBuilder: (context, index) {
                final product = trendingProducts[index];
                return Container(
                  width: MediaQuery.of(context).size.width / 4 - 20,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Ảnh sản phẩm
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                            child: Image.network(
                              product["image"],
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 90,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
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
                          ),
                        ],
                      ),
                      // ✅ căn giữa text giá & giá gốc
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              product["price"],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                            Text(
                              product["originalPrice"],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
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
