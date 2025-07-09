import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), widget.onFinish);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF163458), // Primary Blue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Smart Transport Management',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC88C2C), // Accent Gold
                letterSpacing: 1.1,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}