import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import 'points_history_screen.dart';
import 'my_offers_screen.dart';
import 'points_code_screen.dart';

class MemberScreen extends StatefulWidget {
  const MemberScreen({Key? key}) : super(key: key);

  // Variable to store the currently selected membership level
  static const int MEMBER = 0;
  static const int LOYAL = 1;
  static const int GOLD = 2;
  static const int PLATINUM = 3;

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  int _selectedLevel = MemberScreen.MEMBER; // Default display Member level

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Membership Level'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Membership card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8EECC0), Color(0xFF7EDDB6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Member',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '0 points',
                        style: AppStyles.heading.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Color(0xFF7EDDB6),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Need 1 more point to reach Loyal Member',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // In the membership card section, add a button to display points code
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const PointsCodeScreen()),
                        );
                      },
                      icon: const Icon(Icons.qr_code, color: Color(0xFF7EDDB6)),
                      label: const Text('Show Points Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Points history
            _buildMenuItem(
              context,
              'Points History',
              Icons.history,
              () {
                // Navigate to points history screen
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PointsHistoryScreen()),
                );
              },
            ),
            
            // My offers
            _buildMenuItem(
              context,
              'My Offers',
              Icons.card_giftcard,
              () {
                // Navigate to offers screen
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MyOffersScreen()),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Membership levels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLevel = MemberScreen.MEMBER;
                      });
                    },
                    child: _buildMembershipLevel(
                      'Member', 
                      Icons.person_outline, 
                      Colors.teal, 
                      _selectedLevel == MemberScreen.MEMBER
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLevel = MemberScreen.LOYAL;
                      });
                    },
                    child: _buildMembershipLevel(
                      'Loyal', 
                      Icons.person, 
                      Colors.grey, 
                      _selectedLevel == MemberScreen.LOYAL
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLevel = MemberScreen.GOLD;
                      });
                    },
                    child: _buildMembershipLevel(
                      'Gold', 
                      Icons.star, 
                      Colors.amber, 
                      _selectedLevel == MemberScreen.GOLD
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLevel = MemberScreen.PLATINUM;
                      });
                    },
                    child: _buildMembershipLevel(
                      'Platinum', 
                      Icons.diamond, 
                      Colors.purple, 
                      _selectedLevel == MemberScreen.PLATINUM
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Points accumulation rules and benefits by membership level
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _getBenefitsByLevel(_selectedLevel),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Return list of benefits based on selected membership level
  List<Widget> _getBenefitsByLevel(int level) {
    switch (level) {
      case MemberScreen.LOYAL:
        return [
          _buildBenefitItem('Points rule: 10% of order value'),
          const SizedBox(height: 12),
          _buildBenefitItem('Loyal Member level: From 1 - 1,999,999 points'),
          const SizedBox(height: 12),
          _buildBenefitItem('Free shipping'),
          const SizedBox(height: 12),
          _buildBenefitItem('One 15% discount code for use during birthday month'),
        ];
      case MemberScreen.GOLD:
        return [
          _buildBenefitItem('Points rule: 10% of order value'),
          const SizedBox(height: 12),
          _buildBenefitItem('Gold level: From 2,000,000 - 9,999,999 points'),
          const SizedBox(height: 12),
          _buildBenefitItem('Free shipping'),
          const SizedBox(height: 12),
          _buildBenefitItem('One 15% discount code for use during birthday month'),
        ];
      case MemberScreen.PLATINUM:
        return [
          _buildBenefitItem('Points rule: 10% of order value'),
          const SizedBox(height: 12),
          _buildBenefitItem('Platinum level: From 10,000,000 points'),
          const SizedBox(height: 12),
          _buildBenefitItem('Free shipping'),
          const SizedBox(height: 12),
          _buildBenefitItem('Priority customer care process'),
          const SizedBox(height: 12),
          _buildBenefitItem('One 15% discount code for use during birthday month'),
        ];
      case MemberScreen.MEMBER:
      default:
        return [
          _buildBenefitItem('Points rule: 10% of order value'),
          const SizedBox(height: 12),
          _buildBenefitItem('Free shipping'),
          const SizedBox(height: 12),
          _buildBenefitItem('One 5% discount code for use during birthday month'),
        ];
    }
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipLevel(String title, IconData icon, Color color, bool isActive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? color : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 2,
            width: 40,
            color: AppColors.primary,
          ),
      ],
    );
  }

  Widget _buildBenefitItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: AppColors.primary,
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}