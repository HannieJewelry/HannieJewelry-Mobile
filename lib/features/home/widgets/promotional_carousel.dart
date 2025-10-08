import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/constants/app_colors.dart';

class PromotionalCarousel extends StatefulWidget {
  const PromotionalCarousel({Key? key}) : super(key: key);

  @override
  State<PromotionalCarousel> createState() => _PromotionalCarouselState();
}

class _PromotionalCarouselState extends State<PromotionalCarousel> {
  final CarouselSliderController _controller = CarouselSliderController();
  int activeIndex = 0;

  final List<String> imageUrls = [
    'https://cdn.huythanhjewelry.vn/storage/photos/uploads/cktm-thang-3-03_1747135272.jpg',
    'https://cdn.huythanhjewelry.vn/storage/photos/uploads/cktm-thang-3-09_1747135255.jpg',
    'https://cdn.huythanhjewelry.vn/storage/photos/uploads/nhan-love-not-01_1747130651.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          carouselController: _controller,
          options: CarouselOptions(
            height: 180,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            viewportFraction: 1,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() => activeIndex = index);
            },
          ),
          items: imageUrls.map((url) {
            return Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            );
          }).toList(),
        ),
        Positioned(
          bottom: 8,
          child: AnimatedSmoothIndicator(
            activeIndex: activeIndex,
            count: imageUrls.length,
            effect: const SlideEffect( // dùng SlideEffect để ra hình vuông
              dotHeight: 6,
              dotWidth: 16,
              activeDotColor: AppColors.primary,
              dotColor: Colors.black26,
              spacing: 6,
              radius: 2, // bo góc nhẹ thành hình chữ nhật vuông
            ),
            onDotClicked: (index) {
              _controller.animateToPage(index);
            },
          ),
        ),
      ],
    );
  }
}
