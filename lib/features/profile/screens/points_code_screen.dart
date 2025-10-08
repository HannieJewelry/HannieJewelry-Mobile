import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class PointsCodeScreen extends StatelessWidget {
  const PointsCodeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Points Code'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Membership card with user information and QR code
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB4F0D3), // Light mint green color
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // User name
                    const Text(
                      'John Smith',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Membership level and points
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Color(0xFF7EDDB6),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Member',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF7EDDB6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '0 points',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dotted separator line
                    Row(
                      children: List.generate(
                        30,
                        (index) => Expanded(
                          child: Container(
                            height: 1,
                            color: index % 2 == 0 ? Colors.white : Colors.transparent,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Barcode - Replace image with barcode widget
                    Container(
                      height: 60,
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: CustomPaint(
                        painter: _BarcodePainter('0345807906'),
                        size: const Size(double.infinity, 44),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Code number
                    const Text(
                      '0 3 4 5 8 0 7 9 0 6',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // QR Code
                    QrImageView(
                      data: 'MEMBER-0345807906', // QR code data
                      version: QrVersions.auto,
                      size: 150.0,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Usage instructions
              const Text(
                'Show this code to staff when checking out',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add this class at the end of the file
class _BarcodePainter extends CustomPainter {
  final String data;
  
  _BarcodePainter(this.data);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;
    
    final double barWidth = size.width / (data.length * 7); // Each character has 7 bars (4 black, 3 white)
    double x = 0;
    
    // Draw simple barcode
    for (int i = 0; i < data.length; i++) {
      final charCode = data.codeUnitAt(i) - 48; // Convert from character to number
      
      // Each character is represented by 4 black bars and 3 white spaces
      for (int j = 0; j < 4; j++) {
        final barHeight = size.height - (j % 2 == 0 ? 0 : size.height / 3);
        canvas.drawRect(
          Rect.fromLTWH(x, 0, barWidth, barHeight),
          paint,
        );
        x += barWidth * 1.5;
      }
      
      x += barWidth; // White space between characters
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}