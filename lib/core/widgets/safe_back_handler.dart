import 'package:flutter/material.dart';
import '../../features/home/screens/home_screen.dart';

/// A widget that safely handles back navigation.
/// If it can pop (there are screens in the navigation stack), it will pop.
/// If it cannot pop (it's the only/first screen), it navigates to the home screen instead.
class SafeBackHandler extends StatelessWidget {
  /// The child widget to display.
  final Widget child;
  
  /// Optional callback to execute before handling back navigation.
  final Function()? onWillPop;

  const SafeBackHandler({
    Key? key,
    required this.child,
    this.onWillPop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // We'll handle popping manually
      onPopInvoked: (didPop) {
        if (didPop) return;
        
        // Execute optional callback if provided
        if (onWillPop != null) {
          onWillPop!();
        }
        
        // Handle back navigation safely
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          // If we can't pop (we're the only screen in stack), navigate to home instead
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      },
      child: child,
    );
  }
} 