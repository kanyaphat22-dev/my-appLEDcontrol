import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double progress = 0;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() async {
    while (mounted && progress < 100) {
      await Future.delayed(const Duration(milliseconds: 15));
      if (!mounted) return;
      setState(() {
        progress += 2;
      });
    }
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFd5f3ff),
              Color(0xFF2D9CC8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: screenWidth * 0.8,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: screenWidth * 0.18,
                    height: screenWidth * 0.18,
                    child: CircularProgressIndicator(
                      value: progress / 100,
                      strokeWidth: 8,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF39A8D3), // สีเดียวกับโลโก้
                      ),
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  Text(
                    '${progress.toInt()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // 
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
