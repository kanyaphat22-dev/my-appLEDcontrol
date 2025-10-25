import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'main_screen.dart'; // 👈 หน้าที่คุณต้องการให้เข้าเมื่อเคยล็อกอินแล้ว

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

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

  Future<void> _startLoading() async {
    // ✅ โหลด progress animation
    while (mounted && progress < 100) {
      await Future.delayed(const Duration(milliseconds: 15));
      if (!mounted) return;
      setState(() {
        progress += 2;
      });
    }

    // ✅ ตรวจสอบสถานะล็อกอิน
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      // 🔹 เคยล็อกอิน → ไปหน้า MainScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      // 🔸 ยังไม่เคยล็อกอิน → ไปหน้า Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    const Color bottomColor = Color(0xFF2D9CC8);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: bottomColor,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFd5f3ff),
                  bottomColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // โลโก้แอป
                  Image.asset(
                    'assets/logo.png',
                    width: size.width * 0.8,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  // วงกลมโหลด
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: size.width * 0.18,
                        height: size.width * 0.18,
                        child: CircularProgressIndicator(
                          value: progress / 100,
                          strokeWidth: 8,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF39A8D3),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      Text(
                        '${progress.toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
