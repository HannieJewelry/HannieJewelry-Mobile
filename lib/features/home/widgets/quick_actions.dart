import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {'icon': Icons.local_shipping, 'label': 'Orders', 'color': Colors.blue},
      {'icon': Icons.card_giftcard, 'label': 'Voucher', 'color': Colors.green},
      {'icon': Icons.location_on, 'label': 'City', 'color': Colors.orange},
      {'icon': Icons.local_fire_department, 'label': 'Hot deal', 'color': Colors.red},
      {'icon': Icons.flash_on, 'label': 'Super Sale', 'color': Colors.yellow[700]!},
    ];

    return Container(
         padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((action) {
          return Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: action['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action['icon'],
                  color: action['color'],
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                action['label'],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
