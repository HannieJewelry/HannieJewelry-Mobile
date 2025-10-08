import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../home/screens/home_screen.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? redirectRoute;
  
  const LoginScreen({
    Key? key, 
    this.redirectRoute,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Function to validate phone number
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    
    // Remove spaces and special characters
    final phone = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Check phone number length (10-11 digits)
    if (phone.length < 10 || phone.length > 11) {
      return 'Phone number must be 10-11 digits';
    }
    
    // Check if phone number starts with 0
    if (!phone.startsWith('0')) {
      return 'Phone number must start with 0';
    }
    
    return null;
  }

  Future<void> _sendOTP() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final phone = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Save phone number before sending OTP
    authService.phoneNumber = phone;
    
    final success = await authService.sendOTP(phone);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerificationScreen(
            redirectRoute: widget.redirectRoute,
          ),
        ),
      );
    } else if (mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send verification code. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            bottom: keyboardHeight > 0 ? keyboardHeight + 16 : 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Logo - responsive size
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: screenHeight * 0.35, // 35% of screen height
                        width: screenHeight * 0.35,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.appSlogan,
                        style: AppStyles.bodyText.copyWith(
                          color: AppColors.textLight,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.05), // Responsive spacing
                  // Login form
                  Text(
                    'Enter your phone number to continue',
                    style: AppStyles.bodyText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: 'Enter your phone number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        errorMaxLines: 2,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // OTP info text
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'A one-time verification code will be sent to your phone. The code will expire in 5 minutes.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : CustomButton(
                    text: 'Continue with OTP',
                    onPressed: _sendOTP,
                  ),
                  const SizedBox(height: 16),
                  // Note about automatic registration
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_add_outlined, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'If this is your first time, a new account will be automatically created for you.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Skip button
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    child: Text(
                      AppStrings.skip,
                      style: AppStyles.bodyText.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
