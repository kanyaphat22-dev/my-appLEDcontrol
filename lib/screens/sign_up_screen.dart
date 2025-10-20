import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String fullName = '';
  String email = '';
  String username = '';
  String password = '';

  bool _obscure = true;
  final Color themeBlue = const Color(0xFF1A9ACF); // ฟ้าเข้ม

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // ✅ สีล่างสุดของ gradient (ใช้กับแถบระบบล่าง)
    const Color bottomColor = Color(0xFF1A9ACF);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: bottomColor, // ✅ สีเดียวกับฟ้าล่าง
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true, // ✅ ให้ body ขยายถึงขอบจอ
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          top: false,
          bottom: false, // ✅ ปิด SafeArea ล่าง
          child: Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE0F0FA), // ฟ้าอ่อนบน
                  bottomColor,        // ฟ้าเข้มล่าง
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              height: 80,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: themeBlue,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 1️⃣ Email
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'อีเมล',
                                labelStyle: TextStyle(color: themeBlue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: TextStyle(color: themeBlue),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'กรุณากรอกอีเมล';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(v)) {
                                  return 'อีเมลไม่ถูกต้อง';
                                }
                                return null;
                              },
                              onSaved: (v) => email = v ?? '',
                            ),
                            const SizedBox(height: 16),

                            // 2️⃣ ชื่อ-นามสกุล
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'ชื่อ-นามสกุล',
                                labelStyle: TextStyle(color: themeBlue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: TextStyle(color: themeBlue),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'กรุณากรอกชื่อ-นามสกุล'
                                  : null,
                              onSaved: (v) => fullName = v ?? '',
                            ),
                            const SizedBox(height: 16),

                            // 3️⃣ ชื่อผู้ใช้
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'ชื่อผู้ใช้',
                                labelStyle: TextStyle(color: themeBlue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: TextStyle(color: themeBlue),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'กรุณากรอกชื่อผู้ใช้'
                                  : null,
                              onSaved: (v) => username = v ?? '',
                            ),
                            const SizedBox(height: 16),

                            // 4️⃣ รหัสผ่าน
                            TextFormField(
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'รหัสผ่าน',
                                labelStyle: TextStyle(color: themeBlue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: themeBlue,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscure = !_obscure;
                                    });
                                  },
                                ),
                              ),
                              style: TextStyle(color: themeBlue),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'กรุณากรอกรหัสผ่าน';
                                }
                                if (v.length < 6) {
                                  return 'รหัสผ่านต้องไม่น้อยกว่า 6 ตัวอักษร';
                                }
                                return null;
                              },
                              onSaved: (v) => password = v ?? '',
                            ),
                            const SizedBox(height: 24),

                            // ปุ่มสมัครสมาชิก
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('สมัครสมาชิกสำเร็จ!')),
                                    );

                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ลิงก์ไปหน้า Login
                            RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  color: themeBlue,
                                  fontSize: 16,
                                ),
                                children: [
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Login',
                                        style: TextStyle(
                                          color: themeBlue.withOpacity(0.9),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40), // ✅ เผื่อพื้นที่ล่างสุด
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
