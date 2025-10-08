import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../home/screens/home_screen.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../services/auth_service.dart';
import 'package:flutter/services.dart';
// ...existing code...

class OTPVerificationScreen extends StatefulWidget {
  final String? redirectRoute;
  final bool isRegistration;

  const OTPVerificationScreen({
    super.key, 
    this.redirectRoute,
    this.isRegistration = false,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty || _otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Check if OTP has expired
    if (authService.otpRemainingTime <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP has expired. Please request a new code.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await authService.verifyOTP(_otpController.text);

      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Wait a moment before navigating
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          // Decide where to navigate: if profile incomplete, go to EditProfileScreen
          final user = authService.currentUser;
          bool needsProfileCompletion() {
            if (user == null) return true;
            // If user has empty id (created as fallback) or only phone without name/email, treat as incomplete
            final hasId = (user.id.isNotEmpty);
            final hasName = (user.name.isNotEmpty && user.name != 'User');
            final hasEmail = (user.email != null && user.email!.isNotEmpty);
            final hasDob = (user.dateOfBirth != null && user.dateOfBirth!.isNotEmpty);
            // Consider profile complete when name and either email or dateOfBirth present
            return !(hasId && hasName && (hasEmail || hasDob));
          }

          if (needsProfileCompletion()) {
            // Navigate user to Edit Profile so they can complete their information
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              (route) => false,
            );
            return;
          }

          // Otherwise navigate to home screen or redirect route
          if (widget.redirectRoute != null) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              widget.redirectRoute!,
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        });
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid or expired OTP code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatRemainingTime(int seconds) {
    if (seconds <= 0) {
      return "Expired";
    }
    
    // Format time as minutes:seconds
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final phoneNumber = authService.phoneNumber ?? '';
    final otpRemainingTime = authService.otpRemainingTime;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            bottom: keyboardHeight > 0 ? keyboardHeight + 16 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'OTP Verification',
                style: AppStyles.heading,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the verification code sent to $phoneNumber',
                style: AppStyles.bodyTextSmall,
              ),
              const SizedBox(height: 16),
              // OTP expiration timer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: otpRemainingTime > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: otpRemainingTime > 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Code expires in: ${_formatRemainingTime(otpRemainingTime)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: otpRemainingTime > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // OTP Input Field
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: "000000",
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  // Auto-submit when 6 digits are entered
                  if (value.length == 6) {
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Verify',
                      onPressed: _verifyOTP,
                    ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: otpRemainingTime <= 0 ? () {
                    if (phoneNumber.isNotEmpty) {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      authService.sendOTP(phoneNumber);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('New OTP has been sent'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } : null,
                  child: Text(
                    otpRemainingTime <= 0 ? 'Resend code' : 'Wait ${_formatRemainingTime(otpRemainingTime)} to resend',
                    style: AppStyles.bodyText.copyWith(
                      color: otpRemainingTime <= 0 ? AppColors.primary : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}