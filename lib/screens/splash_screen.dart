import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final size = MediaQuery.of(context).size;

    // ✅ สีล่างสุดของ gradient ใช้เป็นสี systemNavigationBar ด้วย
    const Color bottomColor = Color(0xFF2D9CC8);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // โปร่งใสด้านบน
        systemNavigationBarColor: bottomColor, // สีล่างสุดของ gradient
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true, // ✅ ให้เนื้อหาลงถึงขอบล่างจริง
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          bottom: false, // ✅ ปิด SafeArea ล่าง เพื่อให้ gradient ลงถึงขอบ
          child: Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFd5f3ff), // ฟ้าอ่อนบน
                  bottomColor,        // ฟ้าเข้มล่าง
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
                    width: size.width * 0.8,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
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
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60), // ✅ กันขีด gesture ทับ
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
