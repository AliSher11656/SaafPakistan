import 'package:flutter/material.dart';

class OrderConfirmation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF00401A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Checkmark Icon
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: screenHeight * 0.2,
            ),
            SizedBox(height: screenHeight * 0.05),

            // Pickup Scheduled Text
            Text(
              'Pickup Scheduled!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
